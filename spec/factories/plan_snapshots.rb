# frozen_string_literal: true

require_relative '../support/mocks/plan_snapshot_values'

FactoryBot.define do
  factory :plan_snapshot do
    association :plan
    version { 1 }
    visibility { PlanSnapshot.visibilities.keys.first }
    rda_json { PlanSnapshotValues.mock_rda_json }
    extension_json { PlanSnapshotValues.mock_extension_json }
    checksum { PlanSnapshotChecksum.calculate(rda_json, extension_json) }
    fixity_checked_at { nil }

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
