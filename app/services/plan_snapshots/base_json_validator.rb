# frozen_string_literal: true

module PlanSnapshots
  # Shared helpers for JSON-path based validators.
  class BaseJsonValidator
    def initialize(payload)
      @payload = payload
    end

    private

    attr_reader :payload

    def all_required_values_present?(paths, root: payload)
      paths.all? { |path| value_at(path, root: root).present? }
    end

    def value_at(path, root: payload)
      return nil unless root.respond_to?(:dig)

      root.dig(*path)
    end
  end
end
