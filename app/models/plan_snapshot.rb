# frozen_string_literal: true

class PlanSnapshot < ApplicationRecord
  belongs_to :plan

  validates :version, presence: true, numericality: { only_integer: true, greater_than: 0 }
  validates :rda_json, presence: true
  # Prevent two snapshots from having the same (plan_id, version) pairing
  # (Mirrors the unique db index on [:plan_id, :version])
  validates :plan_id, uniqueness: { scope: :version }

  # Scope to fetch snapshots for a given plan ordered by version
  scope :for_plan, ->(plan) { where(plan_id: plan.id).order(version: :asc) }

  def self.create_for_plan(plan)
    create!(
      plan: plan,
      version: next_version_for_plan(plan),
      rda_json: plan.to_rda_json,
      additional_json: plan.to_additional_json
    )
  end

  # Get the most recent snapshot of a plan
  def self.latest_for_plan_id(plan_id)
    where(plan_id: plan_id).order(version: :desc).first
  end

  def self.next_version_for_plan(plan)
    (where(plan_id: plan.id).maximum(:version) || 0) + 1
  end
end

# What needs to be saved for `additional_data`?
# We definitely need template questions and answers
# Do we need additional template data as well (e.g. sections and phases)?
# Templates already have versioning implmented, so maybe only a template.id
# is needed for reference, rather than an entire extra snapshot.
# - Figure out if you can edit a template without creating a new version
