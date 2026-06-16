# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'ResearchOutputs DOI Fetching', type: :request do
  let(:user) { create(:user) }
  let(:plan) { create(:plan) }
  let(:doi) { '10.5281/zenodo.4884775' }
  let(:base_url) { 'https://api.datacite.org' }

  before do
    create(:role, :creator, user: user, plan: plan)

    sign_in user

    Rails.configuration.x.datacite = ActiveSupport::OrderedOptions.new if Rails.configuration.x.datacite.nil?
    Rails.configuration.x.datacite.active = true
  end

  describe 'GET /plans/:plan_id/research_outputs/fetch_doi' do
    context 'with a valid DOI' do
      let(:datacite_json) do
        {
          data: {
            attributes: {
              titles: [{ title: 'Example dataset' }],
              descriptions: [
                { description: 'Abstract description text...', descriptionType: 'Abstract' }
              ],
              types: { resourceTypeGeneral: 'Dataset' },
              published: '2021'
            }
          }
        }.to_json
      end

      before do
        stub_datacite_request(body: datacite_json, headers: { 'Content-Type' => 'application/json' })
      end

      it 'returns a successful 200 OK JSON response' do
        get fetch_doi_plan_research_outputs_path(plan, doi: doi)

        expect(response.code).to eql('200')
        expect(response.content_type).to include('application/json')

        json_response = JSON.parse(response.body)
        expect(json_response['title']).to eq('Example dataset')
        expect(json_response['output_type']).to eq('dataset')
      end
    end

    context 'when given a full DOI URL instead of a raw identifier' do
      let(:full_url_doi) { "https://doi.org/#{doi}" }
      let(:datacite_json) do
        { data: { attributes: { titles: [{ title: 'URL Stripped Output' }],
                                types: { resourceTypeGeneral: 'Software' } } } }.to_json
      end

      it 'strips the domain protocol prefix and fetches successfully' do
        stub_datacite_request(body: datacite_json)

        get fetch_doi_plan_research_outputs_path(plan, doi: full_url_doi)

        json_response = JSON.parse(response.body)
        expect(json_response['doi']).to eq(doi)
        expect(json_response['output_type']).to eq('software')
      end
    end

    context 'when descriptions do not contain an explicit Abstract type' do
      let(:datacite_json) do
        {
          data: {
            attributes: {
              titles: [{ title: 'Fallback Desc Output' }],
              descriptions: [{ description: 'First general description block text.' }],
              types: { resourceTypeGeneral: 'Text' }
            }
          }
        }.to_json
      end

      it 'falls back to prefilling with the first description element' do
        stub_datacite_request(body: datacite_json)

        get fetch_doi_plan_research_outputs_path(plan, doi: doi)

        json_response = JSON.parse(response.body)
        expect(json_response['description']).to eq('First general description block text.')
      end
    end

    context 'when DataCite returns an unmapped or missing resourceTypeGeneral' do
      let(:datacite_json) do
        {
          data: {
            attributes: {
              titles: [{ title: 'Unknown Type Output' }],
              types: { resourceTypeGeneral: 'UnrecognizedType' }
            }
          }
        }.to_json
      end

      it 'defaults the output type to other' do
        stub_datacite_request(body: datacite_json)

        get fetch_doi_plan_research_outputs_path(plan, doi: doi)

        json_response = JSON.parse(response.body)
        expect(json_response['output_type']).to eq('other')
      end
    end

    context 'when DOI parameter is missing' do
      it 'returns a 400 Bad Request JSON response' do
        get fetch_doi_plan_research_outputs_path(plan, doi: '')

        expect(response.code).to eql('400')
        expect(JSON.parse(response.body)['error']).to eq('DOI is required')
      end
    end

    context 'when the service cannot find the DOI' do
      before do
        stub_datacite_request(target_doi: 'invalid-doi', status: 404, body: '')
      end

      it 'returns a 404 Not Found JSON response' do
        get fetch_doi_plan_research_outputs_path(plan, doi: 'invalid-doi')
        expect(response.code).to eql('404')
      end
    end
  end
end

def stub_datacite_request(target_doi: doi, status: 200, body: '', headers: {})
  escaped_path = target_doi == 'invalid-doi' ? 'invalid-doi' : CGI.escape(target_doi)

  stub_request(:get, "#{base_url}/dois/#{escaped_path}")
    .with(headers: { 'Accept' => 'application/vnd.api+json' })
    .to_return(status: status, body: body, headers: headers)
end
