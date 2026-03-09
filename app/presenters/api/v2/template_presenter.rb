# frozen_string_literal: true

module Api
  module V2
    # Helper class for the API V2 template info
    class TemplatePresenter
      include Api::V2::SanitizationService

      def initialize(template:)
        @template = template
      end

      # If the plan has a grant number then it has been awarded/granted
      # otherwise it is 'planned'
      def title
        title = plain_text(@template.title)
        return title unless @template.customization_of.present?

        org_name = plain_text(@template.org.name)
        "#{title} - with additional questions for #{org_name}"
      end
    end
  end
end
