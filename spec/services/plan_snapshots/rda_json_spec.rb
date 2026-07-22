# frozen_string_literal: true

require 'rails_helper'
require_relative '../../support/mocks/plan_snapshot_values'

RSpec.describe PlanSnapshots::RdaJson do
  let(:reader) do
    described_class.new(
      rda_json: PlanSnapshotValues.mock_rda_json
    )
  end

  describe '#identifier' do
    it 'returns dmp_id.identifier' do
      expect(reader.identifier).to eq(
        PlanSnapshotValues.mock_plan_identifier_url
      )
    end
  end

  describe '#identifier_type' do
    it 'returns dmp_id.type' do
      expect(reader.identifier_type).to eq('url')
    end
  end
end
