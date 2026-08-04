# frozen_string_literal: true

module PlanSnapshots
  # Validates required Extension JSON fields used by PlanSnapshot readers/views.
  # See PlanSnapshotValues.mock_extension_json for schema example
  class ExtensionJsonValidator
    def initialize(json)
      @json = json
    end

    def valid?
      required_template_fields_present? && any_question_answered?
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

    def any_question_answered?
      all_questions.any? { |question| question.answer.text.present? }
    end

    def all_questions
      extension_json.template.phases.flat_map(&:sections).flat_map(&:questions)
    end
  end
end
