# frozen_string_literal: true

require 'rails_helper'

RSpec.describe PlanSnapshots::FixityCheckRunner do
  subject(:runner) { described_class.new }

  describe '#call' do
    context 'when all snapshots succeed' do
      let!(:snapshots) { create_list(:plan_snapshot, 2, :stale) }

      it 'returns aggregated ok counts' do
        expect(runner.call).to eq(ok: 2)
      end
    end

    context 'when snapshots have mixed results' do
      let!(:ok_snapshot) { create(:plan_snapshot, :stale) }
      let!(:failed_snapshot) { create(:plan_snapshot, :stale, :tampered) }

      it 'aggregates ok and failed counts' do
        expect(runner.call).to eq(ok: 1, failed: 1)
      end
    end
  end
end
