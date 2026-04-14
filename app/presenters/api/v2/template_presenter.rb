# frozen_string_literal: true

module Api
  module V2
    # Helper class for the API V2 template info
    class TemplatePresenter
      def initialize(template:)
        @template = template
      end

      # If the plan has a grant number then it has been awarded/granted
      # otherwise it is 'planned'
      def title
        return @template.title unless @template.customization_of.present?

        "#{@template.title} - with additional questions for #{@template.org.name}"
      end

      def questions
        @template.phases.flat_map do |phase|
          phase.sections.flat_map(&:questions)
        end
      end
    end
  end
end
