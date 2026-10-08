# frozen_string_literal: true

module Api
  module CommonMadmp
    # Free-text query filtering for the Common MADMP API.
    #
    # This is intentionally narrow and allow-listed to the human-readable DMP
    # fields called out in the Common MADMP API spec: plan title/description and
    # dataset title/description. It does not treat query as a generic
    # structured-field filter.
    module QueryFiltering
      extend ActiveSupport::Concern

      # Note plans.title and plans.description are also exposed in the project sub-object
      # (see app/views/api/v2/plans/_project.json.jbuilder), so this may need a
      # follow-up if the contract starts distinguishing project metadata from the
      # plan-level metadata.
      QUERY_SEARCH_FIELDS = [
        'LOWER(plans.title) LIKE ?',
        'LOWER(plans.description) LIKE ?',
        'LOWER(research_outputs.title) LIKE ?',
        'LOWER(research_outputs.description) LIKE ?'
      ].freeze

      private

      def query_filter(scope, query_values)
        query_values = normalize_query_values(query_values)
        return scope if query_values.empty?

        conditions, parameters = query_conditions(query_values)

        scope.left_joins(:research_outputs)
             .where(conditions.join(' OR '), *parameters)
             .distinct
      end

      def normalize_query_values(query_values)
        Array(query_values).flatten.compact
                           .map { |item| item.to_s.strip }
                           .reject(&:blank?)
      end

      # Build the SQL conditions and corresponding parameters for each query value.
      # For example, "foo" produces one condition and parameter for each
      # searchable field, all using the same "%foo%" pattern.
      def query_conditions(query_values)
        query_values.each_with_object([[], []]) do |query_value, (conditions, parameters)|
          pattern = query_pattern(query_value)
          conditions.concat(QUERY_SEARCH_FIELDS)
          parameters.concat(Array.new(QUERY_SEARCH_FIELDS.length, pattern))
        end
      end

      def query_pattern(query_value)
        escaped_value = ActiveRecord::Base.sanitize_sql_like(query_value.downcase)
        "%#{escaped_value}%"
      end
    end
  end
end
