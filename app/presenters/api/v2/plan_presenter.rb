# frozen_string_literal: true

module Api
  module V2
    # Helper class for the API V2 project / DMP
    class PlanPresenter
      attr_reader :data_contact, :contributors, :costs, :complete_plan_data

      def initialize(plan:, complete: false, for_common_madmp_api: false)
        @contributors = []
        return unless plan.present?

        @plan = plan
        @for_common_madmp_api = for_common_madmp_api

        # Use owner or first data_curation role as the data_contact
        @data_contact = @plan.owner || @plan.contributors.find(&:data_curation?)
        @contributors = @plan.contributors.to_a

        @costs = plan_costs(plan: @plan)

        @complete_plan_data = fetch_all_q_and_a if complete
      end

      # Extract the canonical ARK or DOI for the DMP OR use its URL if none exists
      # TODO: When snapshot DOI minting is implemented, keep version-specific
      #       identifiers in snapshot resolution flow and preserve this as the
      #       canonical plan-level identifier.
      def identifier
        doi = @plan.identifiers.select do |id|
          ::Plan::DMP_ID_TYPES.include?(id.identifier_format)
        end
        return doi.first if doi.first.present?

        # If no DOI is present, fall back to a URL for the plan itself.
        # TODO: This should eventually use the canonical app-level plan URL
        # (for example `plan_url(@plan)` or the shared plan route), not always the
        # API v2 endpoint, because the identifier may be used outside the v2 API
        # context and should point to the underlying plan resource instead.
        Identifier.new(value: Rails.application.routes.url_helpers.api_v2_plan_url(@plan))
      end

      private

      # Retrieve the answers that have the Budget theme.
      #
      # NOTE: The DB currently has no "Cost" theme, so this lookup always
      # returns nil and the cost payload is never populated.
      #
      # TODO: align this with the Common-MaDMP contract. The current mapping is
      # not schema-compatible:
      # - value is derived from freeform answer text instead of a numeric field
      # - currency_code is effectively hardcoded and not validated against ISO 4217
      # - the output can violate the schema contract by type/value even when present
      def plan_costs(plan:)
        theme = Theme.where(title: 'Cost').first
        return [] unless theme.present?

        # TODO: define a new 'Currency' question type that includes a float field
        #       and a currency type selector (e.g. GBP or USD)
        answers = plan.answers
                      .joins(question: :themes)
                      .where(themes: { id: theme.id })
                      .includes(:question)

        answers.map do |answer|
          # TODO: Investigate whether question level guidance should be the description
          { title: answer.question.text, description: nil,
            currency_code: 'usd', value: answer.text }
        end
      end

      # Fetch all questions and answers from a plan, regardless of theme
      def fetch_all_q_and_a
        answers = @plan.answers
        return [] unless answers.present?

        answers.filter_map do |answer|
          next unless answer.answered?

          q = answer.question
          next unless q.present?

          {
            id: q.id,
            title: "Question #{q.number || q.id}",
            section: q.section&.title,
            question: q.text.to_s,
            answer: answer.text.to_s
          }
        end
      end
    end
  end
end
