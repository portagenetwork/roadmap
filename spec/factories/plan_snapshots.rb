# frozen_string_literal: true

require_relative '../support/mocks/plan_snapshot_values'

FactoryBot.define do
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
