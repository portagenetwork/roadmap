# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ExternalApis::DataciteService, type: :service do
  let(:doi) { '10.5281/zenodo.4884775' }

  before do
    Rails.configuration.x.datacite.active = true
    Rails.configuration.x.datacite.repository_id = 'MY_REPO'
    Rails.configuration.x.datacite.password = 'SECRET'
    Rails.configuration.x.datacite.api_base_url = 'https://api.datacite.org'
    Rails.configuration.x.datacite.test_api_base_url = 'https://api.test.datacite.org'
  end

  describe '.parse_attributes' do
    context 'when given a valid JSON payload' do
      let(:raw_json) do
        {
          data: {
            attributes: {
              titles: [{ title: 'Helper Function Test Title' }],
              descriptions: [
                { descriptionType: 'Other', description: 'Ignored description' },
                { descriptionType: 'Abstract', description: 'Explicit abstract text.' }
              ],
              types: { resourceTypeGeneral: 'Software' },
              registered: '2023-05-12'
            }
          }
        }.to_json
      end

      it 'correctly extracts and structures all metadata fields' do
        result = described_class.parse_attributes(raw_json, doi)

        expect(result).to eq({
                               title: 'Helper Function Test Title',
                               description: 'Explicit abstract text.',
                               output_type: :software,
                               release_date: '2023-05-12',
                               doi: doi
                             })
      end
    end

    context 'when the payload is missing data attributes entirely' do
      it 'returns nil safely without raising an error' do
        empty_json = { data: {} }.to_json

        expect(described_class.parse_attributes(empty_json, doi)).to be_nil
      end
    end
  end

  describe 'description extraction helpers' do
    context 'when descriptions do not contain an explicit Abstract type' do
      let(:no_abstract_json) do
        {
          data: {
            attributes: {
              titles: [{ title: 'Fallback Desc Output' }],
              descriptions: [
                { description: 'First general description block text.' },
                { description: 'Second description text.' }
              ],
              types: { resourceTypeGeneral: 'Text' }
            }
          }
        }.to_json
      end

      it 'falls back to picking the first available description element' do
        result = described_class.parse_attributes(no_abstract_json, doi)

        expect(result[:description]).to eq('First general description block text.')
      end
    end

    context 'when the descriptions array is empty or nil' do
      let(:empty_desc_json) do
        {
          data: {
            attributes: {
              titles: [{ title: 'No Description Output' }],
              descriptions: [],
              types: { resourceTypeGeneral: 'Dataset' }
            }
          }
        }.to_json
      end

      it 'returns nil for the description field' do
        result = described_class.parse_attributes(empty_desc_json, doi)

        expect(result[:description]).to be_nil
      end
    end
  end

  describe 'Resource Output type mapping' do
    context 'when DataCite returns an unmapped or missing resourceTypeGeneral' do
      let(:unknown_type_json) do
        {
          data: {
            attributes: {
              titles: [{ title: 'Unknown Type Output' }],
              types: { resourceTypeGeneral: 'UnrecognizedType' }
            }
          }
        }.to_json
      end

      it 'defaults the output type symbol to :other' do
        result = described_class.parse_attributes(unknown_type_json, doi)

        expect(result[:output_type]).to eq(:other)
      end
    end

    context 'when mapping standard known DataCite general types' do
      it 'correctly translates specific types into application symbols' do
        dataset_json = { data: { attributes: { titles: [{ title: 'T' }],
                                               types: { resourceTypeGeneral: 'Dataset' } } } }.to_json
        text_json = { data: { attributes: { titles: [{ title: 'T' }],
                                            types: { resourceTypeGeneral: 'Text' } } } }.to_json

        expect(described_class.parse_attributes(dataset_json, doi)[:output_type]).to eq(:dataset)
        expect(described_class.parse_attributes(text_json, doi)[:output_type]).to eq(:text)
      end
    end
  end

  describe '.mint_doi' do
    let(:payload) { { data: { type: 'dois', attributes: { prefix: '10.83996' } } } }
    let(:response_body) { { data: { id: '10.83996/1234', type: 'dois' } }.to_json }

    context 'when integration is disabled' do
      before { Rails.configuration.x.datacite.active = false }

      it 'raises an error before sending a request' do
        expect { described_class.mint_doi(payload: payload) }
          .to raise_error(StandardError, /disabled or credentials missing/)
      end
    end

    context 'when integration is enabled' do
      it 'sends a POST request with basic auth and payload' do
        datacite_stub = stub_request(:post, 'https://api.test.datacite.org/dois')
                        .with(
                          body: payload.to_json,
                          headers: {
                            'Content-Type' => 'application/vnd.api+json',
                            'Accept' => 'application/vnd.api+json'
                          },
                          basic_auth: %w[MY_REPO SECRET]
                        )
                        .to_return(status: 201, body: response_body)

        result = described_class.mint_doi(payload: payload)

        expect(datacite_stub).to have_been_requested
        expect(result).to eq({ 'data' => { 'id' => '10.83996/1234', 'type' => 'dois' } })
      end

      context 'when DataCite returns an error status' do
        before do
          stub_request(:post, 'https://api.test.datacite.org/dois')
            .to_return(status: 422, body: 'Unprocessable Entity')
        end

        it 're-raises the API error response' do
          expect { described_class.mint_doi(payload: payload) }
            .to raise_error(StandardError, /DataCite API Error \[422\]/)
        end
      end
    end
  end

  describe '.update_doi' do
    let(:raw_doi_id) { 'https://doi.org/10.83996/1234' }
    let(:payload) { { data: { type: 'dois', attributes: { event: 'publish' } } } }
    let(:response_body) { { data: { id: '10.83996/1234', type: 'dois' } }.to_json }

    it 'strips the DOI prefix, CGI escapes the ID, and sends a PUT request' do
      put_stub = stub_request(:put, 'https://api.test.datacite.org/dois/10.83996%2F1234')
                 .with(
                   body: payload.to_json,
                   basic_auth: %w[MY_REPO SECRET]
                 )
                 .to_return(status: 200, body: response_body)

      described_class.update_doi(doi_id: raw_doi_id, payload: payload)

      expect(put_stub).to have_been_requested
    end
  end
end
