# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ExternalApis::DoiResolutionService, type: :service do
  let(:user) { create(:user) }
  let(:plan) { create(:plan) }
  let(:doi) { '10.5281/zenodo.4884775' }
  let(:datacite_base_url) { 'https://api.datacite.org' }
  let(:crossref_base_url) { 'https://api.crossref.org' }

  let(:datacite_body) do
    { data: { attributes: {
      titles: [{ title: 'DataCite Document' }],
      descriptions: [{ description: 'DataCite Abstract' }],
      types: { resourceTypeGeneral: 'Dataset' },
      registered: '2021-05-12'
    } } }.to_json
  end

  let(:crossref_body) do
    { message: {
      title: ['Crossref Publication'],
      abstract: 'Crossref Abstract',
      type: 'journal-article',
      issued: { 'date-parts': [[2026, 7]] }
    } }.to_json
  end

  before do
    create(:role, :creator, user: user, plan: plan)

    Rails.configuration.x.datacite.active = true
    Rails.configuration.x.crossref.active = true

    Rails.cache.clear
  end

  describe '.fetch_metadata' do
    context 'when DataCite has the record' do
      it 'successfully cleans the input string, gets DataCite data, and ignores Crossref' do
        messy_doi = "  https://doi.org/#{doi}  "

        dc_stub = stub_request(:get, "#{datacite_base_url}/dois/10.5281%2Fzenodo.4884775")
                  .to_return(status: 200, body: datacite_body)

        cr_stub = stub_request(:get, %r{api.crossref.org/works/})

        result = described_class.fetch_metadata(doi: messy_doi)

        expect(result[:status]).to eq(:ok)
        expect(result[:metadata][:title]).to eq('DataCite Document')
        expect(result[:metadata][:doi]).to eq(doi)
        expect(result[:metadata][:release_date]).to eq('2021-05-12')
        expect(dc_stub).to have_been_requested
        expect(cr_stub).not_to have_been_requested
      end
    end

    context 'when DataCite fails but Crossref has the record' do
      it 'automatically falls back to Crossref' do
        dc_stub = stub_request(:get, "#{datacite_base_url}/dois/10.5281%2Fzenodo.4884775")
                  .to_return(status: 404, body: '')

        # Fixed: Match the %2F URL encoding expected by HTTParty
        cr_stub = stub_request(:get, "#{crossref_base_url}/works/10.5281%2Fzenodo.4884775")
                  .to_return(status: 200, body: crossref_body)

        result = described_class.fetch_metadata(doi: doi)

        expect(result[:title]).to eq('Crossref Publication')
        expect(result[:output_type]).to eq(:text)
        expect(dc_stub).to have_been_requested
        expect(cr_stub).to have_been_requested
      end
    end

    context 'when both services fail to locate the asset' do
      it 'returns nil safely' do
        stub_request(:get, /api.datacite.org/).to_return(status: 404)
        stub_request(:get, /api.crossref.org/).to_return(status: 404)

        expect(described_class.fetch_metadata(doi: doi)).to be_nil
      end
    end
  end

  describe '.execute_fetch' do
    context 'when a service is explicitly deactivated in the configuration' do
      it 'short-circuits instantly and returns nil without making network calls' do
        Rails.configuration.x.datacite.active = false

        dc_stub = stub_request(:get, /api.datacite.org/)

        # Bypass private scope using Ruby's .send method (3 arguments)
        result = described_class.send(:execute_fetch, ExternalApis::DataciteService, 'datacite', doi)

        expect(result).to be_nil
        expect(dc_stub).not_to have_been_requested
      end
    end

    context 'when the network layer encounters an error' do
      it 'gracefully intercepts HTTP timeouts and returns nil instead of crashing' do
        stub_request(:get, "#{datacite_base_url}/dois/10.5281%2Fzenodo.4884775")
          .to_raise(Timeout::Error)

        result = described_class.send(:execute_fetch, ExternalApis::DataciteService, 'datacite', doi)

        expect(result).to be_nil
      end

      it 'gracefully intercepts JSON response parsing exceptions' do
        stub_request(:get, "#{datacite_base_url}/dois/10.5281%2Fzenodo.4884775")
          .to_return(status: 200, body: 'Not Valid JSON { [')

        result = described_class.send(:execute_fetch, ExternalApis::DataciteService, 'datacite', doi)

        expect(result).to be_nil
      end
    end
  end
end
