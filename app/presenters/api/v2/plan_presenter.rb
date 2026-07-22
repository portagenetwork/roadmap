# frozen_string_literal: true

module Api
  module V2
    # Helper class for the API V2 project / DMP
    class PlanPresenter
      attr_reader :data_contact, :contributors, :costs, :complete_plan_data

      def initialize(plan:, complete: false)
        @contributors = []
        return unless plan.present?

        @plan = plan

        # Use owner or first data_curation role as the data_contact
        @data_contact = @plan.owner || @plan.contributors.find(&:data_curation?)
        @contributors = @plan.contributors.to_a

        @costs = plan_costs(plan: @plan)

        @complete_plan_data = fetch_all_q_and_a if complete
      end

      # Extract the ARK or DOI for the DMP OR use its URL if none exists
      def identifier
        doi = @plan.identifiers.select do |id|
          ::Plan::DMP_ID_TYPES.include?(id.identifier_format)
        end
        return doi.first if doi.first.present?

        # if no DOI then use the URL for the API's 'show' method
        Identifier.new(value: Rails.application.routes.url_helpers.api_v2_plan_url(@plan))
      end

      private

      # Retrieve the answers that have the Budget theme
      def plan_costs(plan:)
        theme = Theme.where(title: 'Cost').first
        return [] unless theme.present?

        # TODO: define a new 'Currency' question type that includes a float field
        #       any currency type selector (e.g GBP or USD)
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
        return [] if answers.blank?

        answers.filter_map { |answer| build_q_and_a_item(answer) }
      end

      def build_q_and_a_item(answer)
        formatted_answer = answer.serialized_answer_text
        return if formatted_answer.blank?

        q = answer.question
        {
          id: q.id,
          title: "Question #{q.number || q.id}",
          section: q.section&.title,
          question: ActionController::Base.helpers.strip_tags(q.text),
          answer: ActionController::Base.helpers.strip_tags(formatted_answer)
        }
      end
    end
  end
end
