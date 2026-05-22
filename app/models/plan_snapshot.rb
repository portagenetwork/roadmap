# frozen_string_literal: true

# Represents a version/snapshot of a Plan, capturing its state and metadata at a specific point in time.
class PlanSnapshot < ApplicationRecord
  # ==============
  # = Attributes =
  # ==============

  enum visibility: %i[privately_visible organisationally_visible publicly_visible]

  # ================
  # = Associations =
  # ================

  belongs_to :plan

  # ===============
  # = Validations =
  # ===============

  validates :visibility, inclusion: { in: visibilities.keys }
  validates :version, presence: true, numericality: { only_integer: true, greater_than: 0 }
  validates :rda_json, presence: true
  validates :extension_json, presence: true
  validates :checksum, presence: true, format: { with: /\A[a-f0-9]{32}\z/i, message: 'must be a valid MD5 hex string' }
  validates :plan_id, uniqueness: { scope: :version }

  # =================
  # = Class Methods =
  # =================

  # Create a new snapshot from the given plan.
  def self.create_from_plan(plan:, visibility:)
    rda_json = Api::V2::Serialization::RdaSerializer.call(plan: plan)
    extension_json = Api::V2::Serialization::ExtensionSerializer.call(plan: plan)

    create!(
      plan: plan,
      visibility: visibility,
      version: next_version_for_plan(plan),
      rda_json: rda_json,
      extension_json: extension_json,
      checksum: PlanSnapshotChecksum.calculate(rda_json, extension_json)
    )
  end

  def self.next_version_for_plan(plan)
    (where(plan_id: plan.id).maximum(:version) || 0) + 1
  end

  private_class_method :next_version_for_plan
end
