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

  # Get the most recent snapshot of a plan
  def self.latest_for_plan_id(plan_id)
    where(plan_id: plan_id).order(version: :desc).first
  end
end
