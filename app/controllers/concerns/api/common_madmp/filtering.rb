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

      # Keys expected as a single scalar value.
      SCALAR_FILTER_KEYS = (%w[title] + DATE_FILTERS.keys).freeze

      # Keys expected as an array of values (per spec, repeated as
      # `key[]=a&key[]=b`), combined with OR semantics across the values.
      ARRAY_FILTER_KEYS = %w[query].freeze

      # This can be expanded to include additional supported DMP fields.
      ALLOWED_FILTER_KEYS = (SCALAR_FILTER_KEYS + ARRAY_FILTER_KEYS).freeze

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

      # rejects the whole request (returning {}) if any candidate value doesn't
      # match its expected shape, rather than silently dropping or coercing it.
      # The spec requires a 400 (invalid_query_string) for a parameter-type mismatch,
      # so we check shape explicitly instead of relying on `permit` to just drop it.
      def normalized_params
        candidates = params.slice(*ALLOWED_FILTER_KEYS).to_unsafe_h
        # `to_unsafe_h` normalizes any nested ActionController::Parameters into a
        # plain Hash, so we check for that in `well_formed?``
        unless well_formed?(candidates)
          invalid_query_string_error(error_message: filter_error_message)
          return {}
        end

        params.permit(*SCALAR_FILTER_KEYS, query: []).to_h
      end

      # SCALAR_FILTER_KEYS must arrive as a single value.
      # ARRAY_FILTER_KEYS must arrive as an array.
      #
      # Either direction of mismatch is a shape violation:
      #   - `title[]=a&title[]=b` (scalar key sent as an array)
      #   - `title[foo]=bar` (scalar key sent as a nested hash)
      #   - `query=foo` instead of `query[]=foo` (array key sent as a scalar)
      def well_formed?(candidates)
        candidates.all? do |key, value|
          if ARRAY_FILTER_KEYS.include?(key)
            value.is_a?(Array)
          else
            !value.is_a?(Array) && !value.is_a?(Hash)
          end
        end
      end

      # Every key here is guaranteed to be a member of ALLOWED_FILTER_KEYS, since
      # supported_filters has already filtered on that allow-list. There is
      # deliberately no "unsupported key" branch: unsupported params are
      # silently ignored upstream in supported_filters, not surfaced as an
      # error here.
      def apply_filter(scope, key, value)
        case key
        when 'query'
          query_filter(scope, value)
        when 'title'
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

      # Per spec, multiple query values are combined with OR: a DMP matches
      # if it satisfies any of the listed values, and each value is matched
      # against any of the allow-listed fields below.
      def query_filter(scope, value)
        terms = Array(value).flatten.compact.map(&:to_s).map(&:strip).reject(&:blank?)
        return scope if terms.empty?

        # NOTE: This intentionally mirrors the parent plan text fields in a narrow,
        # allow-listed way. The same text is also exposed in the project sub-object
        # (see app/views/api/v2/plans/_project.json.jbuilder), so this may need a
        # follow-up if the contract starts distinguishing project metadata from the
        # plan-level metadata.
        field_conditions = [
          'LOWER(plans.title) LIKE ?',
          'LOWER(plans.description) LIKE ?',
          'LOWER(research_outputs.title) LIKE ?',
          'LOWER(research_outputs.description) LIKE ?'
        ]

        grouped_conditions = terms.map do |term|
          escaped = ActiveRecord::Base.sanitize_sql_like(term.downcase)
          pattern = "%#{escaped}%"
          [field_conditions, Array.new(field_conditions.length, pattern)]
        end

        sql = grouped_conditions.map { |conditions, _patterns| conditions.join(' OR ') }.join(' OR ')
        sql_params = grouped_conditions.flat_map { |_conditions, patterns| patterns }

        scope.left_joins(:research_outputs)
             .where(sql, *sql_params)
             .distinct
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
