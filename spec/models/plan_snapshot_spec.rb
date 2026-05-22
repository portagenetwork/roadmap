# frozen_string_literal: true

require 'rails_helper'
require_relative '../support/mocks/plan_snapshot_values'

RSpec.describe PlanSnapshot, type: :model do
  include PlanSnapshotValues
  subject(:plan_snapshot) { described_class.new }

  describe 'associations' do
    it { is_expected.to belong_to(:plan) }
  end

  describe 'validations' do
    it { is_expected.to validate_presence_of(:version) }
    it { is_expected.to validate_numericality_of(:version).only_integer.is_greater_than(0) }
    it { is_expected.to validate_presence_of(:rda_json) }
    it { is_expected.to validate_presence_of(:extension_json) }

    it 'defines the correct enum values for visibility' do
      expect(described_class.visibilities).to eq({
                                                   'privately_visible' => 0,
                                                   'organisationally_visible' => 1,
                                                   'publicly_visible' => 2
                                                 })
    end

    it 'validates presence and format of checksum' do
      snapshot = build(:plan_snapshot, checksum: nil, rda_json: PlanSnapshotValues.mock_rda_json,
                                       extension_json: PlanSnapshotValues.mock_extension_json)
      expect(snapshot).not_to be_valid
      expect(snapshot.errors[:checksum]).to include("can't be blank")

      snapshot = build(:plan_snapshot, checksum: 'invalid', rda_json: PlanSnapshotValues.mock_rda_json,
                                       extension_json: PlanSnapshotValues.mock_extension_json)
      expect(snapshot).not_to be_valid
      expect(snapshot.errors[:checksum]).to include('must be a valid MD5 hex string')

      snapshot = build(:plan_snapshot, checksum: PlanSnapshotValues.random_md5,
                                       rda_json: PlanSnapshotValues.mock_rda_json,
                                       extension_json: PlanSnapshotValues.mock_extension_json)
      expect(snapshot).to be_valid
    end

    # Uniqueness validation: set up a valid record first
    it 'validates uniqueness of plan_id scoped to version' do
      plan = create(:plan)
      create(:plan_snapshot, plan: plan, version: 1)
      duplicate = build(:plan_snapshot, plan: plan, version: 1)
      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:plan_id]).to include('has already been taken')
    end
  end
end
