# frozen_string_literal: true

module Api
  module V2
    # Helper class for rendering API V2 plan snapshot data.
    class PlanSnapshotPresenter
      attr_reader :template

      def initialize(plan:)
        @plan = plan
        @answers_by_question_id = @plan.answers.index_by(&:question_id)
        @template = template_data
      end

      private

      def template_data
        {
          id: @plan.template.id,
          title: @plan.template.title,
          version: @plan.template.version,
          phases: phases
        }
      end

      def phases
        @plan.template.phases.map do |phase|
          {
            title: phase.title,
            number: phase.number,
            sections: sections_for_phase(phase)
          }
        end
      end

      def sections_for_phase(phase)
        phase.sections.map do |section|
          {
            title: section.title,
            number: section.number,
            modifiable: section.modifiable,
            questions: questions_for_section(section)
          }
        end
      end

      def questions_for_section(section)
        section.questions.map do |question|
          {
            id: question.id,
            number: question.number,
            text: question.text.to_s,
            format: question_format(question),
            answer: answer_for(question)
          }
        end
      end

      def question_format(question)
        format = question.question_format

        return unless format

        {
          id: format.id,
          title: format.title
        }
      end

      def answer_for(question)
        answer = @answers_by_question_id[question.id]

        {
          text: answer&.text.to_s,
          question_options: answer_question_options(answer)
        }
      end

      def answer_question_options(answer)
        return [] unless answer

        answer.question_options.map do |option|
          {
            id: option.id,
            text: option.text.to_s
          }
        end
      end
    end
  end
end
