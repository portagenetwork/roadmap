# frozen_string_literal: true

require 'rails_helper'

RSpec.describe PlanSnapshots::FixityCheckService do
  let(:now) { Time.current }

  describe '#call' do
    subject(:service) { described_class.new(snapshot) }

    context 'when snapshot is not due' do
      let(:snapshot) { create(:plan_snapshot, :recently_checked) }

      it 'skips fixity check' do
        result = service.call

        expect(result[:status]).to eq(:skipped)
      end
    end

    context 'when snapshot is due and valid' do
      let(:snapshot) { create(:plan_snapshot, :stale) }

      it 'marks as ok and updates last checked timestamp' do
        result = service.call

        expect(result[:status]).to eq(:ok)
        expect(snapshot.reload.fixity_checked_at).to be_within(1.second).of(now)
      end
    end

    context 'when snapshot is due and invalid' do
      # alter checksum to fail fixity check
      let(:snapshot) { create(:plan_snapshot, :tampered) }

      it 'returns failed without updating timestamp' do
        result = service.call

        expect(result[:status]).to eq(:failed)
        expect(snapshot.reload.fixity_checked_at).to be_nil
      end
    end
  end
end
