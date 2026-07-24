# frozen_string_literal: true

module PlanSnapshots
  # Validates required Extension JSON fields used by PlanSnapshot readers/views.
  # See PlanSnapshotValues.mock_extension_json for schema example
  class ExtensionJsonValidator
    def initialize(json)
      @json = json
    end

    def valid?
      required_template_fields_present? &&
        complete_plan_requirements_met?
    end

    private

    attr_reader :json

    def extension_json
      @extension_json ||= ExtensionJson.new(extension_json: json)
    end

    def required_template_fields_present?
      extension_json.template.id.present? &&
        extension_json.template.title.present?
    end

    def complete_plan_requirements_met?
      extension_json.complete_plan.any? &&
        extension_json.complete_plan.all? { |item| complete_plan_item_valid?(item) }
    end

    def complete_plan_item_valid?(item)
      item.title.present? &&
        item.answer.present? &&
        item.section.present? &&
        item.question.present? &&
        item.question_id.present?
    end
  end
end
