# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ExternalApis::DoiPublisherService, type: :service do
  let!(:datacite_scheme) { create(:identifier_scheme, name: 'datacite', identifier_prefix: nil) }
  let(:plan) { create(:plan, :snapshot_ready) }
  let(:snapshot) { create(:plan_snapshot, plan: plan, version: 2, created_at: 1.day.ago) }

  before do
    Rails.configuration.x.datacite.active = true
    Rails.configuration.x.datacite.repository_id = 'MY_REPO'
    Rails.configuration.x.datacite.password = 'SECRET'
    Rails.configuration.x.datacite.api_base_url = 'https://api.datacite.org'
    Rails.configuration.x.datacite.test_api_base_url = 'https://api.test.datacite.org'
  end

  describe '.publish_snapshot' do
    context 'when datacite IdentifierScheme is missing' do
      before { datacite_scheme.destroy }

      it 'raises an error' do
        expect { described_class.publish_snapshot(snapshot) }
          .to raise_error(StandardError, 'DataCite IdentifierScheme missing')
      end
    end

    context 'when the snapshot has already been published' do
      let!(:existing_doi) do
        create(:identifier, identifiable: snapshot, identifier_scheme: datacite_scheme, value: 'https://doi.org/10.83996/existing-snapshot')
      end

      it 'returns the existing DOI value without making API requests' do
        expect(described_class.publish_snapshot(snapshot)).to eq('https://doi.org/10.83996/existing-snapshot')
      end
    end

    context 'when publishing the first snapshot for a plan' do
      before do
        stub_request(:post, %r{/dois\z})
          .to_return(
            { status: 201, body: { data: { id: '10.83996/canonical-1', type: 'dois' } }.to_json },
            { status: 201, body: { data: { id: '10.83996/snapshot-1', type: 'dois' } }.to_json }
          )

        stub_request(:put, %r{/dois/10.83996%2Fcanonical-1})
          .to_return(status: 200, body: { data: { id: '10.83996/canonical-1', type: 'dois' } }.to_json)
      end

      it 'mints a canonical DOI for the plan and a snapshot DOI for the snapshot' do
        described_class.publish_snapshot(snapshot)

        canonical_identifier = plan.reload.identifiers.find_by(identifier_scheme: datacite_scheme)
        expect(canonical_identifier.value).to eq('https://doi.org/10.83996/canonical-1')

        expect(snapshot.reload.identifier.value).to eq('https://doi.org/10.83996/snapshot-1')
      end
    end

    context 'when publishing a subsequent snapshot on a plan that already has a canonical DOI' do
      let!(:canonical_doi) do
        create(:identifier, identifiable: plan, identifier_scheme: datacite_scheme, value: 'https://doi.org/10.83996/canonical-1')
      end

      let!(:prior_snapshot) do
        create(:plan_snapshot, plan: plan, version: 1, created_at: 2.days.ago)
      end

      let!(:prior_snapshot_doi) do
        create(:identifier, identifiable: prior_snapshot, identifier_scheme: datacite_scheme, value: 'https://doi.org/10.83996/snapshot-1')
      end

      before do
        stub_request(:post, %r{/dois\z})
          .to_return(status: 201, body: { data: { id: '10.83996/snapshot-2', type: 'dois' } }.to_json)

        stub_request(:put, %r{/dois/10.83996%2Fcanonical-1})
          .to_return(status: 200, body: { data: { id: '10.83996/canonical-1', type: 'dois' } }.to_json)
      end

      it 'reuses the canonical DOI and mints a new snapshot DOI' do
        expect { described_class.publish_snapshot(snapshot) }
          .not_to change { plan.identifiers.where(identifier_scheme: datacite_scheme).count }

        expect(snapshot.reload.identifier.value).to eq('https://doi.org/10.83996/snapshot-2')
      end
    end
  end
end
