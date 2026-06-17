# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ExternalApis::DataciteService, type: :service do
  let(:user) { create(:user) }
  let(:plan) { create(:plan) }
  let(:doi) { '10.5281/zenodo.4884775' }
  let(:base_url) { 'https://api.datacite.org' }

  before do
    create(:role, :creator, user: user, plan: plan)
    Rails.configuration.x.datacite.active = true
  end

  context 'when the API returns a response that results in nil' do
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

    it 'does not cache the nil value and retries the network on subsequent calls' do
      stub_datacite_request(body: { data: {} }.to_json)

      # First call should return nil and bypass caching
      expect(described_class.fetch_metadata(doi: doi)).to eq(nil)

      stub_datacite_request(body: { data: {} }.to_json)

      # Second call will hit successfully because skip_nil: true prevented saving nil
      stub_datacite_request(body: datacite_json)

      result = described_class.fetch_metadata(doi: doi)

      expect(result[:description]).to eq('First general description block text.')
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

      result = described_class.fetch_metadata(doi: full_url_doi)

      expect(result[:doi]).to eq(doi)
      expect(result[:output_type]).to eq(:software)
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

      result = described_class.fetch_metadata(doi: doi)

      expect(result[:description]).to eq('First general description block text.')
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

      result = described_class.fetch_metadata(doi: doi)

      expect(result[:output_type]).to eq(:other)
    end
  end
end

def stub_datacite_request(target_doi: doi, status: 200, body: '', headers: {})
  escaped_path = target_doi == 'invalid-doi' ? 'invalid-doi' : CGI.escape(target_doi)

  stub_request(:get, "#{base_url}/dois/#{escaped_path}")
    .with(headers: { 'Accept' => 'application/vnd.api+json' })
    .to_return(status: status, body: body, headers: headers)
end
