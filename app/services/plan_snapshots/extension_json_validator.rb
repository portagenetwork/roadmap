# frozen_string_literal: true

module PlanSnapshots
  # Validates required Extension JSON fields used by PlanSnapshot rendering.
  # See PlanSnapshotValues.mock_extension_json for schema example
  class ExtensionJsonValidator < BaseJsonValidator
    REQUIRED_PATHS = [
      %w[extension]
    ].freeze

    REQUIRED_ENTRY_PATHS = [
      %w[dmproadmap template id],
      %w[dmproadmap template title],
      %w[complete_plan]
    ].freeze

    COMPLETE_PLAN_PATH = %w[complete_plan].freeze

    REQUIRED_COMPLETE_PLAN_FIELDS = %w[
      title
      answer
      section
      question
      question_id
    ].freeze

    def valid?
      all_required_values_present?(REQUIRED_PATHS) && extension_entries_valid?
    end

    private

    def extension_entries_valid?
      entries = value_at(REQUIRED_PATHS.first)
      return false unless entries.is_a?(Array) && entries.any?

      entries.all? { |entry| extension_entry_valid?(entry) }
    end

    def extension_entry_valid?(entry)
      return false unless entry.is_a?(Hash)

      all_required_values_present?(REQUIRED_ENTRY_PATHS, root: entry) &&
        complete_plan_items_valid?(entry)
    end

    def complete_plan_items_valid?(entry)
      complete_plan = value_at(COMPLETE_PLAN_PATH, root: entry)
      return false unless complete_plan.is_a?(Array) && complete_plan.any?

      complete_plan.all? do |item|
        item.is_a?(Hash) &&
          REQUIRED_COMPLETE_PLAN_FIELDS.all? { |field| item[field].present? }
      end
    end
  end
end
