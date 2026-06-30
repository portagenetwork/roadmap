# frozen_string_literal: true

# Represents a version/snapshot of a Plan, capturing its state and metadata at a specific point in time.
class PlanSnapshot < ApplicationRecord
  FIXITY_CHECK_INTERVAL = 1.month
  VISIBILITY_MESSAGE = {
    organisationally_visible: _('organizational'),
    publicly_visible: _('public'),
    privately_visible: _('private')
  }.freeze

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
  validate :checksum_differs_from_last_snapshot, on: :create

  # ==========
  # = Scopes =
  # ==========

  scope :due_for_fixity_check, lambda {
                                 where(fixity_checked_at: nil)
                                   .or(where('fixity_checked_at < ?', FIXITY_CHECK_INTERVAL.ago))
                               }

  scope :for_plan, lambda { |plan|
    where(plan: plan).order(version: :desc)
  }

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

  # ===========================
  # = Public Instance Methods =
  # ===========================

  def recalculated_checksum
    PlanSnapshotChecksum.calculate(rda_json, extension_json)
  end

  def fixity_check_passed?
    return false if checksum.blank?

    # Compare recalculated and stored digest values for snapshot integrity.
    ActiveSupport::SecurityUtils.secure_compare(recalculated_checksum, checksum)
  rescue JSON::ParserError, TypeError
    false
  end

  # Returns true if a fixity check has never been performed,
  # or if the previous check is older than the configured interval.
  def fixity_check_due?
    fixity_checked_at.nil? || fixity_checked_at.before?(FIXITY_CHECK_INTERVAL.ago)
  end

  # Human-readable label for user display
  def visibility_label
    VISIBILITY_MESSAGE[visibility.to_sym]
  end

  delegate :identifier, :identifier_type, to: :rda_json_reader, prefix: :dmp

  private

  def checksum_differs_from_last_snapshot
    return unless checksum.present?

    last_checksum = self.class.for_plan(plan).pick(:checksum)
    errors.add(:checksum, _('matches the last snapshot; plan has not changed')) if last_checksum == checksum
  end

  def rda_json_reader
    @rda_json_reader ||= PlanSnapshotRdaJson.new(rda_json: rda_json)
  end
end
