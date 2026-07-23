# frozen_string_literal: true

require 'rails_helper'
require_relative '../../support/mocks/plan_snapshot_values'

RSpec.describe PlanSnapshots::RdaJson do
  let(:reader) do
    described_class.new(
      rda_json: PlanSnapshotValues.mock_rda_json
    )
  end

  describe '#dmp_id' do
    it 'returns the identifier' do
      expect(reader.dmp_id.identifier).to eq(
        PlanSnapshotValues.mock_plan_identifier_url
      )
    end

    it 'returns the identifier type' do
      expect(reader.dmp_id.type).to eq('url')
    end
  end
end
