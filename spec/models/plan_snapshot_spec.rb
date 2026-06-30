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

  describe 'checksum uniqueness per plan' do
    let(:plan) { create(:plan) }
    let(:checksum) { PlanSnapshotValues.random_md5 }

    it 'is invalid when checksum matches the last snapshot for the same plan' do
      create(:plan_snapshot, plan: plan, version: 1, checksum: checksum)
      duplicate = build(:plan_snapshot, plan: plan, version: 2, checksum: checksum)

      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:checksum]).to include('matches the last snapshot; plan has not changed')
    end

    it 'is valid when checksum differs from the last snapshot' do
      create(:plan_snapshot, plan: plan, version: 1, checksum: checksum)
      new_snapshot = build(:plan_snapshot, plan: plan, version: 2, checksum: PlanSnapshotValues.random_md5)

      expect(new_snapshot).to be_valid
    end

    it 'is valid when it is the first snapshot for the plan' do
      snapshot = build(:plan_snapshot, plan: plan, version: 1, checksum: checksum)

      expect(snapshot).to be_valid
    end
  end

  describe '.create_from_plan' do
    let(:plan) { create(:plan) }
    let(:rda_json) { PlanSnapshotValues.mock_rda_json }
    let(:extension_json) { PlanSnapshotValues.mock_extension_json }
    let(:checksum) { PlanSnapshotValues.random_md5 }

    before(:each) do
      Api::V2::Serialization::RdaSerializer.stubs(:call).returns(rda_json)
      Api::V2::Serialization::ExtensionSerializer.stubs(:call).returns(extension_json)

      PlanSnapshotChecksum.stubs(:calculate).returns(checksum)
    end

    it 'creates a valid snapshot with correct attributes' do
      snapshot = described_class.create_from_plan(plan: plan, visibility: 'privately_visible')
      expect(snapshot).to be_persisted
      expect(snapshot.plan).to eq(plan)
      expect(snapshot.visibility).to eq('privately_visible')
      expect(snapshot.rda_json).to eq(rda_json)
      expect(snapshot.extension_json).to eq(extension_json)
      expect(snapshot.checksum).to eq(checksum)
      expect(snapshot.version).to eq(1)
    end

    it 'increments version for subsequent snapshots' do
      described_class.create_from_plan(plan: plan, visibility: 'privately_visible')
      # Stub `calculate` again for checksum_differs_from_last_snapshot validator
      PlanSnapshotChecksum.stubs(:calculate).returns(PlanSnapshotValues.random_md5)
      snapshot2 = described_class.create_from_plan(plan: plan, visibility: 'privately_visible')
      expect(snapshot2.version).to eq(2)
    end

    it 'raises ActiveRecord::RecordInvalid when plan has not changed since last snapshot' do
      described_class.create_from_plan(plan: plan, visibility: 'privately_visible')

      expect do
        described_class.create_from_plan(plan: plan, visibility: 'privately_visible')
      end.to raise_error(ActiveRecord::RecordInvalid, /matches the last snapshot/)
    end
  end

  describe '.due_for_fixity_check' do
    let!(:never_checked) { create(:plan_snapshot, fixity_checked_at: nil) }
    let!(:stale) { create(:plan_snapshot, :stale) }
    let!(:recently_checked) { create(:plan_snapshot, :recently_checked) }

    it 'includes snapshots that have never been checked' do
      expect(described_class.due_for_fixity_check).to include(never_checked)
    end

    it 'includes snapshots whose fixity check is overdue' do
      expect(described_class.due_for_fixity_check).to include(stale)
    end

    it 'excludes snapshots that were checked recently' do
      expect(described_class.due_for_fixity_check).not_to include(recently_checked)
    end
  end

  describe '.send(:next_version_for_plan)' do
    let(:plan) { create(:plan) }

    it 'returns 1 if no snapshots exist' do
      expect(described_class.send(:next_version_for_plan, plan)).to eq(1)
    end

    it 'returns max version + 1 if snapshots exist' do
      create(:plan_snapshot, plan: plan, version: 1)
      create(:plan_snapshot, plan: plan, version: 2)
      expect(described_class.send(:next_version_for_plan, plan)).to eq(3)
    end
  end

  describe '.for_plan' do
    let(:plan) { create(:plan) }
    let(:other_plan) { create(:plan) }

    it 'returns only snapshots for the specified plan' do
      matching_snapshot = create(:plan_snapshot, plan: plan, version: 1)
      create(:plan_snapshot, plan: other_plan, version: 1)

      expect(described_class.for_plan(plan)).to contain_exactly(matching_snapshot)
    end

    it 'orders snapshots by version descending' do
      first = create(:plan_snapshot, plan: plan, version: 1)
      last = create(:plan_snapshot, plan: plan, version: 2)

      expect(described_class.for_plan(plan)).to eq([last, first])
    end
  end

  describe '#visibility_label' do
    it 'maps enum values to concise labels' do
      expect(build(:plan_snapshot, visibility: 'privately_visible').visibility_label).to eq('private')
      expect(build(:plan_snapshot, visibility: 'organisationally_visible').visibility_label).to eq('organizational')
      expect(build(:plan_snapshot, visibility: 'publicly_visible').visibility_label).to eq('public')
    end

    it 'returns nil for unknown visibility' do
      snapshot = build(:plan_snapshot)
      snapshot.stubs(:visibility).returns('custom_visible')

      expect(snapshot.visibility_label).to be_nil
    end
  end

  describe '#dmp_identifier' do
    it 'returns the dmp_id identifier from rda_json' do
      snapshot = build(:plan_snapshot, rda_json: PlanSnapshotValues.mock_rda_json)

      expect(snapshot.dmp_identifier).to eq(PlanSnapshotValues.mock_plan_identifier_url)
    end
  end

  describe '#dmp_identifier_type' do
    it 'returns the dmp_id type from rda_json' do
      snapshot = build(:plan_snapshot, rda_json: PlanSnapshotValues.mock_rda_json)

      expect(snapshot.dmp_identifier_type).to eq('url')
    end
  end
end
