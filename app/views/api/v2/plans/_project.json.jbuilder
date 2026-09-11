# frozen_string_literal: true

# locals: plan

# NOTE: This mirrors the top-level DMP title/description fields for the project
# sub-object. In the current schema, this is effectively a duplicate of the
# parent plan values, and may need to be revisited if the Common MADMP contract
# is expanded to distinguish project metadata from plan-level metadata.
json.title plan.title
json.description plan.description

json.start plan.start_date&.to_formatted_s(:iso8601)
json.end plan.end_date&.to_formatted_s(:iso8601)

if plan.funder.present? || plan.grant_id.present?
  json.funding [plan] do
    json.partial! 'api/v2/plans/funding', plan: plan
  end
end
