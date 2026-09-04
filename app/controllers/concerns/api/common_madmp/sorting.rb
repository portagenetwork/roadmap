# frozen_string_literal: true

module Api
  module CommonMadmp
    # Provides sorting support for Common MADMP API endpoints, parsing and
    # validating `sort` query params against an allow-list of DMP fields.
    module Sorting
      extend ActiveSupport::Concern

      DEFAULT_SORT = %w[created desc].freeze
      # The Common MADMP API contract states:
      # - "Implementations MUST support at least created,desc. Support for other values is RECOMMENDED."
      # - "Sort fields correspond to top-level DMP fields as specified in the RDA-DMP-Common-Standard"
      # This can be expanded to include any/all supported top-level DMP fields.
      ALLOWED_SORT_FIELDS = {
        'title' => 'title',
        'created' => 'created_at',
        'modified' => 'updated_at'
      }.freeze
      ALLOWED_SORT_DIRECTIONS = %w[asc desc].freeze

      private

      def apply_sorting(scope)
        sorts = parse_sort_params
        return scope if sorts.nil? || performed?

        sorts.each do |field, direction|
          scope = scope.order(field => direction)
        end

        scope
      end

      def parse_sort_params
        raw_sort_values.each_with_object([]) do |value, sorts|
          parsed = parse_sort_value(value)
          return nil if parsed.nil?

          sorts << parsed
        end
      end

      def raw_sort_values
        raw = params[:sort].presence || params['sort'].presence || []
        raw = Array(raw).flatten.compact.map(&:to_s).reject(&:blank?)
        raw.presence || [DEFAULT_SORT.join(',')]
      end

      def parse_sort_value(value)
        field, direction = value.split(',', 2)
        field = field.to_s.strip
        direction = direction.to_s.strip.downcase

        unless valid_sort?(field, direction)
          invalid_query_string_error(error_message: sort_error_message)
          return nil
        end

        [ALLOWED_SORT_FIELDS.fetch(field), direction.to_sym]
      end

      def valid_sort?(field, direction)
        ALLOWED_SORT_FIELDS.key?(field) && ALLOWED_SORT_DIRECTIONS.include?(direction)
      end

      def sort_error_message
        _('The query string contained invalid sort parameters.')
      end
    end
  end
end
