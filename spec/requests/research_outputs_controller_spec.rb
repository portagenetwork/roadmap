# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'ResearchOutputs DOI Fetching', type: :request do
  let(:user) { create(:user) }
  let(:plan) { create(:plan) }
  let(:doi) { '10.5281/zenodo.4884775' }
  let(:base_url) { 'https://api.datacite.org/' }

  before do
    create(:role, :creator, user: user, plan: plan)

    sign_in user

    Rails.configuration.x.datacite = ActiveSupport::OrderedOptions.new if Rails.configuration.x.datacite.nil?
    Rails.configuration.x.datacite.active = true
    Rails.configuration.x.datacite.api_base_url = base_url
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
        stub_request(:get, "#{base_url}dois/#{doi}")
          .with(headers: { 'Accept' => 'application/vnd.api+json' })
          .to_return(status: 200, body: datacite_json, headers: { 'Content-Type' => 'application/json' })
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

    context 'when DOI parameter is missing' do
      it 'returns a 400 Bad Request JSON response' do
        get fetch_doi_plan_research_outputs_path(plan, doi: '')

        expect(response.code).to eql('400')
        expect(JSON.parse(response.body)['error']).to eq('DOI is required')
      end
    end

    context 'when the service cannot find the DOI' do
      before do
        stub_request(:get, "#{base_url}dois/invalid-doi")
          .with(headers: { 'Accept' => 'application/vnd.api+json' })
          .to_return(status: 404, body: '', headers: {})
      end

      it 'returns a 404 Not Found JSON response' do
        get fetch_doi_plan_research_outputs_path(plan, doi: 'invalid-doi')
        expect(response.code).to eql('404')
      end
    end
  end
end
