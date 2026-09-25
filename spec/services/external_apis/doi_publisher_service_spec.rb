# frozen_string_literal: true

require 'rails_helper'

RSpec.describe DoiPublisherService, type: :service do
  let(:plan) { create(:plan, :snapshot_ready) }
  let(:snapshot) { create(:plan_snapshot, plan: plan, version: 2, created_at: 1.day.ago) }

  before do
    create(:identifier_scheme, :datacite)
    Rails.configuration.x.datacite.active = true
    Rails.configuration.x.datacite.repository_id = 'MY_REPO'
    Rails.configuration.x.datacite.password = 'SECRET'
    Rails.configuration.x.datacite.api_base_url = 'https://api.datacite.org'
    Rails.configuration.x.datacite.test_api_base_url = 'https://api.test.datacite.org'
  end

  describe '.publish_snapshot_doi' do
    context 'when datacite IdentifierScheme is missing' do
      before { IdentifierScheme.datacite&.destroy }

      it 'raises an error' do
        expect { described_class.publish_snapshot_doi(snapshot) }
          .to raise_error(StandardError, 'DataCite IdentifierScheme missing')
      end
    end

    context 'when the snapshot has already been published' do
      let!(:existing_doi) do
        create(:identifier, identifiable: snapshot, identifier_scheme: IdentifierScheme.datacite, value: 'https://doi.org/10.83996/existing-snapshot')
      end

      it 'returns the existing DOI value without making API requests' do
        expect(described_class.publish_snapshot_doi(snapshot)).to eq('https://doi.org/10.83996/existing-snapshot')
      end
    end

    context 'when minting a snapshot DOI' do
      before do
        stub_request(:post, %r{/dois\z})
          .to_return(status: 201, body: { data: { id: '10.83996/snapshot-1', type: 'dois' } }.to_json)
      end

      it 'mints a snapshot DOI for the snapshot' do
        described_class.publish_snapshot_doi(snapshot)

        expect(snapshot.reload.identifier.value).to eq('https://doi.org/10.83996/snapshot-1')
      end
    end
  end

  describe '.publish_canonical_and_relationships' do
    context 'when the plan does not have a canonical DOI yet' do
      before do
        stub_request(:post, %r{/dois\z})
          .to_return(status: 201, body: { data: { id: '10.83996/canonical-1', type: 'dois' } }.to_json)

        stub_request(:put, %r{/dois/10.83996%2Fcanonical-1})
          .to_return(status: 200, body: { data: { id: '10.83996/canonical-1', type: 'dois' } }.to_json)
      end

      it 'mints a canonical DOI for the plan and updates its relationships' do
        described_class.publish_canonical_and_relationships(snapshot)

        canonical_identifier = plan.reload.identifiers.find_by(identifier_scheme: IdentifierScheme.datacite)
        expect(canonical_identifier.value).to eq('https://doi.org/10.83996/canonical-1')
        expect(a_request(:put, %r{/dois/10.83996%2Fcanonical-1})).to have_been_made
      end
    end

    context 'when the plan already has a canonical DOI' do
      let!(:canonical_doi) do
        create(:identifier, identifiable: plan, identifier_scheme: IdentifierScheme.datacite, value: 'https://doi.org/10.83996/canonical-1')
      end

      before do
        stub_request(:put, %r{/dois/10.83996%2Fcanonical-1})
          .to_return(status: 200, body: { data: { id: '10.83996/canonical-1', type: 'dois' } }.to_json)
      end

      it 'reuses the existing canonical DOI and updates its relationships' do
        expect { described_class.publish_canonical_and_relationships(snapshot) }
          .not_to change { plan.identifiers.where(identifier_scheme: IdentifierScheme.datacite).count }

        expect(a_request(:put, %r{/dois/10.83996%2Fcanonical-1})).to have_been_made
      end
    end
  end
end
