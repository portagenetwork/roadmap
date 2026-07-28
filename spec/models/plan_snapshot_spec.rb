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
      snapshot = build(:plan_snapshot, checksum: nil)
      expect(snapshot).not_to be_valid
      expect(snapshot.errors[:checksum]).to include("can't be blank")

      snapshot = build(:plan_snapshot, checksum: 'invalid')
      expect(snapshot).not_to be_valid
      expect(snapshot.errors[:checksum]).to include('must be a valid MD5 hex string')

      snapshot = build(:plan_snapshot, plan: create(:plan, :snapshot_ready))
      expect(snapshot).to be_valid
    end

    # Uniqueness validation: set up a valid record first
    it 'validates uniqueness of plan_id scoped to version' do
      plan = create(:plan, :snapshot_ready)
      create(:plan_snapshot, plan: plan, version: 1)
      duplicate = build(:plan_snapshot, plan: plan, version: 1)
      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:plan_id]).to include('has already been taken')
    end

    it 'is invalid when the plan is not ready for snapshot creation' do
      plan = create(:plan)
      snapshot = build(:plan_snapshot, plan: plan)

      expect(snapshot).not_to be_valid
      expect(snapshot.errors[:plan]).to include('is not ready for snapshot creation')
    end
  end

  describe 'checksum uniqueness per plan' do
    let(:plan) { create(:plan, :snapshot_ready) }
    let(:checksum) { SecureRandom.hex }

    it 'is invalid when checksum matches the last snapshot for the same plan' do
      create(:plan_snapshot, plan: plan, version: 1, checksum: checksum)
      duplicate = build(:plan_snapshot, plan: plan, version: 2, checksum: checksum)

      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:base]).to include(
        'A new version cannot be published because the plan has not changed since the last version'
      )
    end

    it 'is valid when checksum differs from the last snapshot' do
      create(:plan_snapshot, plan: plan, version: 1, checksum: checksum)
      new_snapshot = build(:plan_snapshot, plan: plan, version: 2)

      expect(new_snapshot).to be_valid
    end

    it 'is valid when it is the first snapshot for the plan' do
      snapshot = build(:plan_snapshot, plan: plan, version: 1, checksum: checksum)

      expect(snapshot).to be_valid
    end
  end

  describe 'generated JSON validators' do
    let(:snapshot) { build(:plan_snapshot, plan: create(:plan, :snapshot_ready)) }

    it 'does not add JSON validation errors when plan is not snapshot-ready' do
      snapshot.plan.stubs(:snapshot_ready?).returns(false)
      PlanSnapshots::RdaJsonValidator.any_instance.stubs(:valid?).returns(false)
      PlanSnapshots::ExtensionJsonValidator.any_instance.stubs(:valid?).returns(false)

      snapshot.valid?
      expect(snapshot.errors[:rda_json]).to be_empty
      expect(snapshot.errors[:extension_json]).to be_empty
    end

    it 'is valid when RdaJsonValidator returns true' do
      PlanSnapshots::RdaJsonValidator.any_instance.stubs(:valid?).returns(true)

      snapshot.valid?
      expect(snapshot.errors[:rda_json]).to be_empty
    end

    it 'is invalid when RdaJsonValidator returns false' do
      PlanSnapshots::RdaJsonValidator.any_instance.stubs(:valid?).returns(false)

      expect(snapshot).not_to be_valid
      expect(snapshot.errors[:rda_json]).to include(PlanSnapshot::MISSING_REQUIRED_JSON_FIELDS_MESSAGE)
    end

    it 'is valid when ExtensionJsonValidator returns true' do
      PlanSnapshots::ExtensionJsonValidator.any_instance.stubs(:valid?).returns(true)

      snapshot.valid?
      expect(snapshot.errors[:extension_json]).to be_empty
    end

    it 'is invalid when ExtensionJsonValidator returns false' do
      PlanSnapshots::ExtensionJsonValidator.any_instance.stubs(:valid?).returns(false)

      expect(snapshot).not_to be_valid
      expect(snapshot.errors[:extension_json]).to include(PlanSnapshot::MISSING_REQUIRED_JSON_FIELDS_MESSAGE)
    end
  end

  describe 'immutability on update' do
    let(:snapshot) { create(:plan_snapshot) }

    it 'allows updating fixity_checked_at' do
      expect { snapshot.update!(fixity_checked_at: Time.current) }
        .to change { snapshot.reload.fixity_checked_at }
    end

    it 'does not allow updating immutable snapshot fields' do
      checksum = SecureRandom.hex
      expect { snapshot.update!(checksum: checksum) }
        .to raise_error(ActiveRecord::RecordInvalid)

      expect(snapshot.reload.checksum).not_to eq(checksum)
    end
  end

  describe '#destroy' do
    let!(:snapshot) { create(:plan_snapshot) }

    it 'does not destroy the record' do
      expect { snapshot.destroy }.not_to change { PlanSnapshot.count }
    end

    it 'returns false' do
      expect(snapshot.destroy).to eql(false)
    end

    it 'adds an error to the record' do
      snapshot.destroy
      expect(snapshot.errors[:base]).to include('Snapshots cannot be deleted once created')
    end

    it 'raises RecordNotDestroyed when using destroy!' do
      expect { snapshot.destroy! }.to raise_error(ActiveRecord::RecordNotDestroyed)
    end

    it 'still exists in the database afterward' do
      snapshot.destroy
      expect(PlanSnapshot.exists?(snapshot.id)).to eql(true)
    end
  end

  describe '.create_from_plan' do
    let(:plan) { create(:plan, :snapshot_ready) }
    let(:rda_json) { PlanSnapshotValues.mock_rda_json }
    let(:extension_json) { PlanSnapshotValues.mock_extension_json }
    let(:checksum) { SecureRandom.hex }

    before(:each) do
      plan.stubs(:snapshot_ready?).returns(true)

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

    it 'forces private visibility even when a different visibility is passed' do
      snapshot = described_class.create_from_plan(plan: plan, visibility: 'publicly_visible')

      expect(snapshot).to be_persisted
      expect(snapshot.visibility).to eq('privately_visible')
    end

    it 'increments version for subsequent snapshots' do
      described_class.create_from_plan(plan: plan, visibility: 'privately_visible')
      # Stub `calculate` again for checksum_differs_from_last_snapshot validator
      PlanSnapshotChecksum.stubs(:calculate).returns(SecureRandom.hex)
      snapshot2 = described_class.create_from_plan(plan: plan, visibility: 'privately_visible')
      expect(snapshot2.version).to eq(2)
    end

    it 'locks the plan while assigning the next version' do
      plan.expects(:with_lock).yields

      described_class.create_from_plan(plan: plan, visibility: 'privately_visible')
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
    let(:plan) { create(:plan, :snapshot_ready) }

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
    let(:plan) { create(:plan, :snapshot_ready) }
    let(:other_plan) { create(:plan, :snapshot_ready) }

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

  it 'responds to the delegated reader methods without raising' do
    snapshot = build(:plan_snapshot, rda_json: PlanSnapshotValues.mock_rda_json,
                                     extension_json: PlanSnapshotValues.mock_extension_json)

    expect { snapshot.contact }.not_to raise_error
    expect { snapshot.contributors }.not_to raise_error
    expect { snapshot.description }.not_to raise_error
    expect { snapshot.dmp_id }.not_to raise_error
    expect { snapshot.project }.not_to raise_error
    expect { snapshot.title }.not_to raise_error
    expect { snapshot.complete_plan }.not_to raise_error
    expect { snapshot.template }.not_to raise_error
  end
end
