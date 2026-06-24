# frozen_string_literal: true

# Service to handle conditional translation of template content
# based on whether or not it belongs to the default funder organization.
class TemplateTranslationService
  class << self
    # Translates a given attribute for a record if it belongs to the default funder
    # @param record [ActiveRecord::Base] The model instance (Template, Phase, Section, etc.)
    # @param attribute [Symbol, String] The database column name to translate
    # @return [String, nil] The translated or raw string content
    def translate(record, attribute)
      return nil if record.blank?

      value = record.read_attribute(attribute)
      return value if value.blank?

      if default_funder_template?(record)
        # Return translation if it's the default funder
        _(value)
      else
        # Return the exact database value for customized templates
        value
      end
    end

    private

    # Traverses up associations to find the parent template and check its org
    def default_funder_template?(record)
      template = fetch_template_from_record(record)

      return false if template.blank?

      # Check if template belongs to default funder
      template.org_id == Rails.application.config.default_funder_id
    rescue StandardError => e
      Rails.logger.error "Template translation error: #{e.message}"
    end

    def fetch_template_from_record(record) # rubocop:disable Metrics/CyclomaticComplexity,Metrics/PerceivedComplexity
      case record.class.name
      when 'Template'       then record
      when 'Phase'          then record.template
      when 'Section'        then record.phase&.template
      when 'Question'       then record.section&.phase&.template
      when 'Annotation', 'QuestionOption' then record.question&.section&.phase&.template
      end
    end
  end
end
