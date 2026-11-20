# frozen_string_literal: true

require_relative '../support/mocks/plan_snapshot_values'

FactoryBot.define do
# == Schema Information
#
# Table name: plan_snapshots
#
#  id                :bigint(8)        not null, primary key
#  checksum          :string(32)       not null
#  extension_json    :jsonb            not null
#  fixity_checked_at :datetime
#  rda_json          :jsonb            not null
#  version           :integer          not null
#  visibility        :integer          default(0), not null
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#  plan_id           :bigint(8)        not null
#
# Indexes
#
#  index_plan_snapshots_on_fixity_checked_at    (fixity_checked_at)
#  index_plan_snapshots_on_plan_id              (plan_id)
#  index_plan_snapshots_on_plan_id_and_version  (plan_id,version) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (plan_id => plans.id)
#
  factory :plan_snapshot do
    association :plan, :snapshot_ready
    version { 1 }
    visibility { PlanSnapshot.visibilities.keys.first }
    rda_json { PlanSnapshotValues.mock_rda_json }
    extension_json { PlanSnapshotValues.mock_extension_json }
    checksum { SecureRandom.hex }
    fixity_checked_at { nil }

    trait :calculated_checksum do
      checksum { PlanSnapshotChecksum.calculate(rda_json, extension_json) }
    end

    trait :recently_checked do
      fixity_checked_at { PlanSnapshot::FIXITY_CHECK_INTERVAL.ago + 1.second }
    end

    trait :stale do
      fixity_checked_at { PlanSnapshot::FIXITY_CHECK_INTERVAL.ago - 1.second }
    end

    trait :tampered do
      after(:create) do |snapshot|
        snapshot.update_column(:checksum, 'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa')
      end
    end
  end
end
