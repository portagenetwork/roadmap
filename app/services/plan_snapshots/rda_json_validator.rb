# frozen_string_literal: true

module PlanSnapshots
  # Validates required RDA JSON fields used by PlanSnapshot readers/views.
  # TODO: Given the size of the RDA schema spec, this validator will likely need to grow over time.
  # - See https://github.com/RDA-DMP-Common/RDA-DMP-Common-Standard/blob/master/examples/JSON/JSON-schema/1.0/maDMP-schema-1.0.json
  class RdaJsonValidator < BaseJsonValidator
    REQUIRED_PATHS = [
      %w[dmp title],
      %w[dmp dmp_id identifier],
      %w[dmp dmp_id type]
    ].freeze

    PROJECT_PATH = %w[dmp project].freeze
    REQUIRED_PROJECT_FIELDS = %w[start end].freeze

    def valid?
      all_required_values_present?(REQUIRED_PATHS) && project_entries_valid?
    end

    private

    def project_entries_valid?
      entries = value_at(PROJECT_PATH)
      return false unless entries.is_a?(Array) && entries.any?

      entries.all? do |entry|
        entry.is_a?(Hash) && REQUIRED_PROJECT_FIELDS.all? { |field| entry[field].present? }
      end
    end
  end
end
