# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'ResearchOutputs DOI Fetching', type: :request do
  let(:user) { create(:user) }
  let(:plan) { create(:plan) }
  let!(:doi_scheme) do
    create(:identifier_scheme, name: 'doi', identifier_prefix: 'https://doi.org', active: true)
  end
  let(:doi) { '10.5281/zenodo.4884775' }
  let(:datacite_base_url) { 'https://api.datacite.org' }
  let(:crossref_base_url) { 'https://api.crossref.org' }

  let(:datacite_json) do
    {
      data: {
        attributes: {
          titles: [{ title: 'Example dataset' }],
          descriptions: [
            { description: 'Abstract description text...', descriptionType: 'Abstract' }
          ],
          types: { resourceTypeGeneral: 'Dataset' },
          dates: [{ date: '2021-05-12', dateType: 'Issued' }]
        }
      }
    }.to_json
  end

  around do |example|
    original_datacite_active = Rails.configuration.x.datacite.active
    original_crossref_active = Rails.configuration.x.crossref.active
    example.run
  ensure
    Rails.configuration.x.datacite.active = original_datacite_active
    Rails.configuration.x.crossref.active = original_crossref_active
  end

  before do
    create(:role, :creator, user: user, plan: plan)

    sign_in user

    Rails.configuration.x.datacite.active = true
    Rails.configuration.x.crossref.active = true

    Rails.cache.clear
  end

  describe 'DOI lookup' do
    describe 'JSON DOI lookup' do
      it 'returns metadata without saving a research output' do
        datacite_request = stub_datacite_request(
          body: datacite_json,
          headers: { 'Content-Type' => 'application/json' }
        )

        expect do
          get new_plan_research_output_path(plan, format: :json), params: { prefill_doi: doi }
        end.not_to change(ResearchOutput, :count)

        expect(response).to have_http_status(:ok)
        expect(response.parsed_body).to eq(
          'metadata' => {
            'title' => 'Example dataset',
            'description' => 'Abstract description text...',
            'output_type' => 'dataset',
            'release_date' => '2021-05-12'
          },
          'byte_sizable' => true
        )
        expect(datacite_request).to have_been_requested.once
      end

      it 'returns an error when the DOI is not found without changing the existing output' do
        research_output = create(:research_output, plan: plan, title: 'Existing output')
        stub_datacite_request(status: 404)
        stub_crossref_request(status: 404)

        get edit_plan_research_output_path(plan, research_output, format: :json), params: { prefill_doi: doi }

        expect(response).to have_http_status(:unprocessable_entity)
        expect(response.parsed_body.fetch('error')).to include('Could not find metadata')
        expect(research_output.reload.title).to eq('Existing output')
      end

      it 'returns an error when DOI providers are unavailable' do
        stub_datacite_request(status: 500)
        stub_crossref_request(status: 500)

        get new_plan_research_output_path(plan, format: :json), params: { prefill_doi: doi }

        expect(response).to have_http_status(:unprocessable_entity)
        expect(response.parsed_body.fetch('error')).to include('DOI lookup service is currently unavailable')
      end

      it 'validates DOI input without calling providers' do
        datacite_request = stub_request(:get, /api\.datacite\.org/)

        get new_plan_research_output_path(plan, format: :json), params: { prefill_doi: 'bad-doi' }

        expect(response).to have_http_status(:unprocessable_entity)
        expect(response.parsed_body.fetch('error')).to include('Does not appear to be a valid DOI')
        expect(datacite_request).not_to have_been_requested
      end

      it 'requires permission to edit the plan' do
        other_plan = create(:plan)
        datacite_request = stub_request(:get, /api\.datacite\.org/)

        get new_plan_research_output_path(other_plan, format: :json), params: { prefill_doi: doi }

        expect(response).to have_http_status(:forbidden)
        expect(datacite_request).not_to have_been_requested
      end
    end

    it 'supports metadata larger than the cookie session limit' do
      large_description = "A long abstract #{'content ' * 800}"
      large_datacite_json = JSON.parse(datacite_json)
      large_datacite_json['data']['attributes']['descriptions'][0]['description'] = large_description
      stub_datacite_request(
        body: large_datacite_json.to_json,
        headers: { 'Content-Type' => 'application/json' }
      )

      get new_plan_research_output_path(plan, format: :json), params: { prefill_doi: doi }

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body.dig('metadata', 'description')).to eq(large_description.strip)
      expect(session[:doi_prefill_data]).to be_nil
    end

    it 'does not look up a DOI supplied to an HTML form URL' do
      datacite_request = stub_request(:get, /api\.datacite\.org/)
      crossref_request = stub_request(:get, /api\.crossref\.org/)
      research_output = create(:research_output, plan: plan, title: 'Existing output')

      get new_plan_research_output_path(plan), params: { prefill_doi: doi }

      expect(response).to have_http_status(:ok)
      expect(Nokogiri::HTML(response.body).at_css('#doi_lookup_input')['value']).to be_blank
      get edit_plan_research_output_path(plan, research_output), params: { prefill_doi: doi }
      expect(response).to have_http_status(:ok)
      expect(Nokogiri::HTML(response.body).at_css('#research_output_title')['value']).to eq('Existing output')
      expect(datacite_request).not_to have_been_requested
      expect(crossref_request).not_to have_been_requested
    end
  end

  describe 'DOI persistence on research outputs' do
    let(:research_output_params) do
      {
        title: 'Output with DOI',
        output_type: 'dataset',
        access: 'open',
        prefill_doi: doi
      }
    end

    it 'persists the DOI identifier using the active doi IdentifierScheme when creating a research output' do
      expect(IdentifierScheme.by_name('doi').first).to eq(doi_scheme)

      post plan_research_outputs_path(plan), params: { prefill_doi: doi, research_output: research_output_params }

      expect(response).to redirect_to(plan_research_outputs_path(plan))

      research_output = ResearchOutput.order(:id).last
      identifier = research_output.identifier_for_scheme(scheme: 'doi')
      expect(identifier).to be_present
      expect(identifier.identifier_scheme).to eq(doi_scheme)
      expect(identifier.value_without_scheme_prefix).to eq(doi)
    end

    it 'replaces the DOI identifier when updating a research output' do
      research_output = create(:research_output, plan: plan, repositories_count: 0, metadata_standards_count: 0)
      research_output.identifiers.create!(identifier_scheme: doi_scheme, value: '10.1111/original-doi')

      patch plan_research_output_path(plan, research_output), params: {
        prefill_doi: doi,
        research_output: {
          title: research_output.title,
          output_type: research_output.output_type,
          access: research_output.access
        }
      }

      expect(response).to redirect_to(plan_research_outputs_path(plan))

      research_output.reload
      identifier = research_output.identifier_for_scheme(scheme: 'doi')
      expect(research_output.identifiers.where(identifier_scheme: doi_scheme).count).to eq(1)
      expect(identifier.value_without_scheme_prefix).to eq(doi)
    end

    it 'shows the persisted DOI on the edit form when no prefill param is supplied' do
      research_output = create(:research_output, plan: plan, repositories_count: 0, metadata_standards_count: 0)
      research_output.identifiers.create!(identifier_scheme: doi_scheme, value: doi)

      get edit_plan_research_output_path(plan, research_output)

      expect(response).to have_http_status(:ok)
      document = Nokogiri::HTML(response.body)
      expect(document.at_css('#doi_lookup_input')['value']).to eq(doi)
    end

    it 'updates the existing research output from DOI prefill without creating a new record' do
      research_output = create(
        :research_output,
        plan: plan,
        title: 'Original title',
        description: 'Original description',
        output_type: 'text',
        release_date: '2020-01-01'
      )

      datacite_request = stub_datacite_request(
        body: datacite_json,
        headers: { 'Content-Type' => 'application/json' }
      )

      get edit_plan_research_output_path(plan, research_output, format: :json), params: { prefill_doi: doi }

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body.dig('metadata', 'title')).to eq('Example dataset')
      expect(response.parsed_body.dig('metadata', 'release_date')).to eq('2021-05-12')

      original_count = ResearchOutput.count

      patch plan_research_output_path(plan, research_output), params: {
        prefill_doi: doi,
        research_output: {
          title: 'Example dataset',
          description: 'Abstract description text...',
          output_type: 'dataset',
          access: research_output.access,
          release_date: '2021-05-12'
        }
      }

      expect(response).to redirect_to(plan_research_outputs_path(plan))
      expect(datacite_request).to have_been_requested.once
      expect(ResearchOutput.count).to eq(original_count)

      research_output.reload
      expect(research_output.title).to eq('Example dataset')
      expect(research_output.description).to include('Abstract description text...')
      expect(research_output.output_type).to eq('dataset')
      expect(research_output.release_date.to_date).to eq(Date.parse('2021-05-12'))
      expect(research_output.identifier_for_scheme(scheme: 'doi')&.value_without_scheme_prefix).to eq(doi)
    end

    it 'removes the DOI identifier when clearing the DOI field on update' do
      research_output = create(:research_output, plan: plan, repositories_count: 0, metadata_standards_count: 0)
      research_output.identifiers.create!(identifier_scheme: doi_scheme, value: doi)

      patch plan_research_output_path(plan, research_output), params: {
        prefill_doi: '',
        research_output: {
          title: research_output.title,
          output_type: research_output.output_type,
          access: research_output.access
        }
      }

      expect(response).to redirect_to(plan_research_outputs_path(plan))

      research_output.reload
      expect(research_output.identifier_for_scheme(scheme: 'doi')).to be_nil
    end

    it 'does not create a research output when an invalid DOI is submitted on save' do
      expect do
        post plan_research_outputs_path(plan),
             params: { prefill_doi: 'bad-doi', research_output: research_output_params }
      end.not_to change(ResearchOutput, :count)

      expect(response).to have_http_status(:ok)
      expect(response.body).to include('Does not appear to be a valid DOI.')
      expect(Nokogiri::HTML(response.body).at_css('#doi_lookup_input')['value']).to eq('bad-doi')
    end

    it 'does not update a research output when an invalid DOI is submitted on save' do
      research_output = create(:research_output, plan: plan, title: 'Original title', repositories_count: 0,
                                                 metadata_standards_count: 0)
      research_output.identifiers.create!(identifier_scheme: doi_scheme, value: doi)

      patch plan_research_output_path(plan, research_output), params: {
        prefill_doi: 'bad-doi',
        research_output: { title: 'Updated title', output_type: research_output.output_type,
                           access: research_output.access }
      }

      expect(response).to have_http_status(:ok)
      expect(response.body).to include('Does not appear to be a valid DOI.')
      expect(Nokogiri::HTML(response.body).at_css('#doi_lookup_input')['value']).to eq('bad-doi')
      expect(research_output.reload.title).to eq('Original title')
      expect(research_output.identifier_for_scheme(scheme: 'doi')&.value_without_scheme_prefix).to eq(doi)
    end

    describe 'replacing repository and metadata standard selections' do
      let(:research_output) { create(:research_output, plan: plan, title: 'Original title') }
      let(:new_repository) { create(:repository) }
      let(:new_metadata_standard) { create(:metadata_standard) }
      let(:updated_output_params) do
        {
          title: 'Updated title',
          output_type: research_output.output_type,
          access: research_output.access,
          repositories_attributes: { '0' => { id: new_repository.id } },
          metadata_standards_attributes: { '0' => { id: new_metadata_standard.id } }
        }
      end

      before do
        research_output.identifiers.create!(identifier_scheme: doi_scheme, value: doi)
      end

      it 'preserves existing selections when an invalid DOI prevents an update' do
        Rails.configuration.x.madmp.stubs(:enable_repository_selection).returns(true)
        Rails.configuration.x.madmp.stubs(:enable_metadata_standard_selection).returns(true)
        original_repository = research_output.repositories.first
        original_metadata_standard = research_output.metadata_standards.first

        patch plan_research_output_path(plan, research_output),
              params: { prefill_doi: 'bad-doi', research_output: updated_output_params }

        expect(response).to have_http_status(:ok)
        expect(flash[:alert]).to match(/does not appear to be a valid DOI/i)
        document = Nokogiri::HTML(response.body)
        expect(document.at_css('#research_output_title')['value']).to eq('Updated title')
        expect(document.at_css('#doi_lookup_input')['value']).to eq('bad-doi')
        expect(document.at_css("input[name*='repositories_attributes'][value='#{new_repository.id}']")).to be_present
        expect(document.at_css("input[name*='metadata_standards_attributes'][value='#{new_metadata_standard.id}']"))
          .to be_present

        research_output.reload
        aggregate_failures do
          expect(research_output.title).to eq('Original title')
          expect(research_output.identifier_for_scheme(scheme: 'doi')&.value_without_scheme_prefix).to eq(doi)
          expect(research_output.repositories).to contain_exactly(original_repository)
          expect(research_output.metadata_standards).to contain_exactly(original_metadata_standard)
        end
      end

      it 'replaces existing selections when the update succeeds' do
        new_doi = '10.1111/new-doi'

        patch plan_research_output_path(plan, research_output),
              params: { prefill_doi: new_doi, research_output: updated_output_params }

        expect(response).to redirect_to(plan_research_outputs_path(plan))
        research_output.reload
        expect(research_output.title).to eq('Updated title')
        expect(research_output.identifier_for_scheme(scheme: 'doi')&.value_without_scheme_prefix).to eq(new_doi)
        expect(research_output.repositories).to contain_exactly(new_repository)
        expect(research_output.metadata_standards).to contain_exactly(new_metadata_standard)
      end
    end

    it 'preserves existing selections when another validation prevents an update' do
      research_output = create(:research_output, plan: plan)
      original_repository = research_output.repositories.first
      original_metadata_standard = research_output.metadata_standards.first

      patch plan_research_output_path(plan, research_output), params: {
        prefill_doi: doi,
        research_output: { title: '', output_type: research_output.output_type, access: research_output.access }
      }

      expect(response).to have_http_status(:ok)
      research_output.reload
      expect(research_output.identifier_for_scheme(scheme: 'doi')).to be_nil
      expect(research_output.repositories).to contain_exactly(original_repository)
      expect(research_output.metadata_standards).to contain_exactly(original_metadata_standard)
    end

    it 'removes existing selections when a valid update submits none' do
      research_output = create(:research_output, plan: plan)

      patch plan_research_output_path(plan, research_output), params: {
        prefill_doi: doi,
        research_output: { title: research_output.title, output_type: research_output.output_type,
                           access: research_output.access }
      }

      expect(response).to redirect_to(plan_research_outputs_path(plan))
      research_output.reload
      expect(research_output.repositories).to be_empty
      expect(research_output.metadata_standards).to be_empty
    end

    it 'normalizes a full DOI URL when saved without clicking Fetch & Add' do
      post plan_research_outputs_path(plan), params: {
        prefill_doi: "  https://doi.org/#{doi}  ",
        research_output: research_output_params
      }

      identifier = ResearchOutput.order(:id).last.identifier_for_scheme(scheme: 'doi')
      expect(identifier.value_without_scheme_prefix).to eq(doi)
    end
  end

  private

  def stub_datacite_request(target_doi: doi, status: 200, body: '', headers: {})
    escaped_path = CGI.escape(target_doi)

    stub_request(:get, "#{datacite_base_url}/dois/#{escaped_path}")
      .with(headers: { 'Accept' => 'application/vnd.api+json' })
      .to_return(status: status, body: body, headers: headers)
  end

  def stub_crossref_request(target_doi: doi, status: 200, body: '', headers: {})
    escaped_path = CGI.escape(target_doi)

    stub_request(:get, "#{crossref_base_url}/works/#{escaped_path}")
      .with(headers: { 'Accept' => 'application/json' })
      .to_return(status: status, body: body, headers: headers)
  end
end
