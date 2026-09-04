# frozen_string_literal: true

module Api
  module CommonMadmp
    # Filtering support for the Common MADMP API.
    module Filtering
      extend ActiveSupport::Concern

      # Maps each date filter key to the column it constrains and whether it's
      # a lower (:gte) or upper (:lte) bound.
      DATE_FILTERS = {
        'created_after' => ['plans.created_at', :gte],
        'created_before' => ['plans.created_at', :lte],
        'modified_after' => ['plans.updated_at', :gte],
        'modified_before' => ['plans.updated_at', :lte]
      }.freeze

      # This can be expanded to include additional supported DMP fields.
      ALLOWED_FILTER_KEYS = (%w[title] + DATE_FILTERS.keys).freeze

      private

      def apply_filters(scope)
        supported_filters.each do |key, value|
          scope = apply_filter(scope, key, value)
          return scope if performed?
        end

        scope
      end

      def supported_filters
        normalized_params.each_with_object({}) do |(key, value), filters|
          # Don't 400 on blank values
          next unless value.present?

          filters[key] = value
        end
      end

      # All keys here are scalar-only per the API spec. If a client sends one
      # as an array (e.g. `title[]=a&title[]=b`) or a nested hash (e.g.
      # `title[foo]=bar`), that's a parameter-type mismatch, and the spec
      # requires a 400 (invalid_query_string) rather than silently ignoring
      # the filter — so we check for that shape explicitly instead of
      # relying on `permit` to just drop it.
      def normalized_params
        scalar_candidates = params.slice(*ALLOWED_FILTER_KEYS).to_unsafe_h
        if scalar_candidates.any? { |_, v| v.is_a?(Array) || v.is_a?(Hash) }
          invalid_query_string_error(error_message: filter_error_message)
          return {}
        end

        params.permit(*ALLOWED_FILTER_KEYS).to_h
      end

      # Every key here is guaranteed to be a member of ALLOWED_FILTER_KEYS, since
      # supported_filters has already filtered on that allow-list. There is
      # deliberately no "unsupported key" branch: unsupported params are
      # silently ignored upstream in supported_filters, not surfaced as an
      # error here.
      def apply_filter(scope, key, value)
        if key == 'title'
          title_filter(scope, value)
        else
          date_filter(scope, key, value)
        end
      end

      def title_filter(scope, value)
        # Escape any literal "%"/"_" in the search term so they're matched as plain
        # characters, not SQL wildcards.
        escaped = ActiveRecord::Base.sanitize_sql_like(value.to_s.strip.downcase)
        scope.where('LOWER(plans.title) LIKE ?', "%#{escaped}%")
      end

      def date_filter(scope, key, value)
        date = Date.parse(value.to_s)
      rescue ArgumentError
        invalid_query_string_error(error_message: filter_error_message)
        scope
      else
        column, bound = DATE_FILTERS.fetch(key)

        case bound
        when :gte
          scope.where("#{column} >= ?", date.beginning_of_day)
        when :lte
          scope.where("#{column} <= ?", date.end_of_day)
        end
      end

      def filter_error_message
        _('The query string contained invalid filter parameters.')
      end
    end
  end
end
