# frozen_string_literal: true

# locals: plan

json.schema 'https://github.com/RDA-DMP-Common/RDA-DMP-Common-Standard/tree/master/examples/JSON/JSON-schema/1.0'

# This flag lets the Common-MaDMP render path opt into its own contract
# without altering the legacy v2 API behavior. We keep the root v2 payload
# shared and vary only the small set of differences we need at render time.
for_common_madmp_api = local_assigns[:for_common_madmp_api]

presenter = Api::V2::PlanPresenter.new(
  plan: plan,
  complete: @complete,
  for_common_madmp_api: for_common_madmp_api
)

# Note the symbol of the dmproadmap json object
# nested in extensions which is the container for the json template object, etc.

# A JSON representation of a Data Management Plan in the
# RDA Common Standard format
json.title plan.title
json.description plan.description
json.language Api::V2::LanguagePresenter.three_char_code(
  lang: plan.owner&.language&.abbreviation
)
json.created plan.created_at.to_formatted_s(:iso8601)
json.modified plan.updated_at.to_formatted_s(:iso8601)

json.ethical_issues_exist Api::V2::ConversionService.boolean_to_yes_no_unknown(plan.ethical_issues)
json.ethical_issues_description sanitize(plan.ethical_issues_description)
json.ethical_issues_report plan.ethical_issues_report

id = presenter.identifier
if id.present?
  json.dmp_id do
    json.partial! 'api/v2/identifiers/show', identifier: id
  end
end

# NOTE: contact is a required field in the Common-MaDMP DMPData schema.
# The app currently only emits it when a data contact is present, which means
# we are relying on an application-level lookup to satisfy a required contract.
if presenter.data_contact.present?
  json.contact do
    json.partial! 'api/v2/contributors/show', contributor: presenter.data_contact,
                                              is_contact: true
  end
end

unless @minimal
  if presenter.contributors.any?
    json.contributor presenter.contributors do |contributor|
      json.partial! 'api/v2/contributors/show', contributor: contributor,
                                                is_contact: false
    end
  end

  # NOTE: This branch never emits a cost array.
  # presenter.costs is currently always empty because
  # there is no "Cost" Theme in the DB.
  if presenter.costs.any?
    json.cost presenter.costs do |cost|
      json.partial! 'api/v2/plans/cost', cost: cost
    end
  end

  json.project [plan] do |pln|
    json.partial! 'api/v2/plans/project', plan: pln
  end

  outputs = plan.research_outputs.any? ? plan.research_outputs : [plan]

  json.dataset outputs do |output|
    json.partial! "api/v2/datasets/show", output: output
  end

  # NOTE: This is a DMPRoadmap extension and it is not part of the Common-
  # MaDMP schema-defined core payload. There is an open RDA discussion about how
  # extension fields should be represented in the standard; for now we keep this
  # application-specific data attached to the DMP document but separate from the
  # schema-defined core payload.
  # See: https://github.com/RDA-DMP-Common/RDA-DMP-Common-Standard/issues/27
  json.partial! 'api/v2/plans/extension', plan: plan, presenter: presenter unless @rda_only
end
