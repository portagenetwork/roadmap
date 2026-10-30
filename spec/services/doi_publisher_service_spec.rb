# frozen_string_literal: true

require 'rails_helper'

RSpec.describe DoiPublisherService, type: :service do
  include_context 'with datacite configuration'

  let(:plan) { create(:plan, :snapshot_ready) }
  let(:snapshot) { create(:plan_snapshot, plan: plan, version: 2, created_at: 1.day.ago) }

  before do
    create(:identifier_scheme, :datacite)
  end

  describe '.publish_snapshot_doi' do
    context 'when datacite IdentifierScheme is missing' do
      before { IdentifierScheme.find_by(name: 'datacite')&.destroy }

      it 'raises an ActiveRecord::RecordNotFound error' do
        expect { described_class.publish_snapshot_doi(snapshot) }
          .to raise_error(ActiveRecord::RecordNotFound)
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

  describe '.update_canonical_and_relationships' do
    context 'when the plan already has a canonical DOI' do
      let!(:canonical_doi) do
        create(:identifier, identifiable: plan, identifier_scheme: IdentifierScheme.datacite, value: 'https://doi.org/10.83996/canonical-1')
      end

      before do
        stub_request(:put, %r{/dois/10.83996%2Fcanonical-1})
          .to_return(status: 200, body: { data: { id: '10.83996/canonical-1', type: 'dois' } }.to_json)
      end

      it 'reuses the existing canonical DOI and updates its relationships' do
        expect { described_class.update_canonical_and_relationships(snapshot) }
          .not_to change { plan.identifiers.where(identifier_scheme: IdentifierScheme.datacite).count }

        expect(a_request(:put, %r{/dois/10.83996%2Fcanonical-1})).to have_been_made
      end
    end
  end
end
