# frozen_string_literal: true

module PlanSnapshots
  # Validates required RDA JSON fields used by PlanSnapshot readers/views.
  # TODO: Given the size of the RDA schema spec, this validator will likely need to grow over time.
  class RdaJsonValidator
    def initialize(json)
      @json = json
    end

    def valid?
      title_present? &&
        required_dmp_id_fields_present? &&
        required_project_fields_present?
    end

    private

    attr_reader :json

    def rda_json
      @rda_json ||= RdaJson.new(rda_json: json)
    end

    def title_present?
      rda_json.title.present?
    end

    def required_dmp_id_fields_present?
      rda_json.dmp_id.identifier.present? &&
        rda_json.dmp_id.type.present?
    end

    def required_project_fields_present?
      rda_json.project.start_date.present? &&
        rda_json.project.end_date.present?
    end
  end
end
