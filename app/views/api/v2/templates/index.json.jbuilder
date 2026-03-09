# frozen_string_literal: true

@sanitizer ||= Object.new.extend(Api::V2::SanitizationService)

json.partial! 'api/v2/standard_response', total_items: @total_items

json.items @items do |template|
  presenter = Api::V2::TemplatePresenter.new(template: template)

  json.dmp_template do
    json.title @sanitizer.plain_text(presenter.title)
    json.description @sanitizer.rich_text(template.description)
    json.version template.version
    json.created template.created_at.to_formatted_s(:iso8601)
    json.modified template.updated_at.to_formatted_s(:iso8601)

    json.affiliation do
      json.partial! 'api/v2/orgs/show', org: template.org
    end

    json.template_id do
      identifier = Api::V2::ConversionService.to_identifier(context: @application,
                                                            value: template.id)
      json.partial! 'api/v2/identifiers/show', identifier: identifier
    end
  end
end
