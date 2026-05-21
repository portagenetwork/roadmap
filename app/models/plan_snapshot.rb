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
end
