# frozen_string_literal: true

module Api
  module CommonMadmp
    # Concern that conforms to pagination requirements as specified in the Common MaDMP API spec
    module Pagination
      extend ActiveSupport::Concern

      DEFAULT_OFFSET = 0
      DEFAULT_COUNT = 20
      MAX_COUNT = 100

      private

      # retrieve the requested pagination params or use defaults
      def pagination_params
        @offset = parse_integer_param('offset', DEFAULT_OFFSET)
        return if performed?

        @count = parse_integer_param('count', default_count)
        return if performed?

        invalid_query_string_error(error_message: pagination_error_message) unless valid_pagination_params?
      end

      def paginate_response(results:)
        results = results.page(@offset).per(@count)
        @total_items = results.total_count
        results
      end

      def parse_integer_param(key, default)
        value = params[key]
        return default unless params.key?(key) && value.present?

        begin
          # Strict integer parsing (not `.to_i`) so malformed values raise
          # instead of silently coercing to 0 (e.g. "abc")
          Integer(value, 10)
        rescue ArgumentError, TypeError
          invalid_query_string_error(
            error_message: pagination_error_message
          )
          nil
        end
      end

      def valid_pagination_params?
        @offset >= 0 && @count >= 1 && @count <= max_count
      end

      # Clamp to max_count in case api_max_page_size is configured below
      # DEFAULT_COUNT — otherwise an unspecified `count` param could still
      # fail valid_pagination_params? and 400 on a request that asked for
      # nothing unusual.
      def default_count
        [DEFAULT_COUNT, max_count].min
      end

      def max_count
        @max_count ||= begin
          count = Rails.configuration.x.application.api_max_page_size.to_i
          count.zero? || count > MAX_COUNT ? MAX_COUNT : count
        end
      end

      def pagination_error_message
        _('The query string contained invalid pagination parameters.')
      end
    end
  end
end
