# frozen_string_literal: true

require_relative '../support/mocks/plan_snapshot_values'

FactoryBot.define do
  factory :plan_snapshot do
    association :plan
    version { 1 }
    visibility { PlanSnapshot.visibilities.keys.first }
    rda_json { PlanSnapshotValues.mock_rda_json }
    extension_json { PlanSnapshotValues.mock_extension_json }
    checksum { PlanSnapshotValues.random_md5 }
    fixity_checked_at { nil }
  end
end
