# frozen_string_literal: true

# locals: plan

json.title plan.title
json.description plan.description

json.start plan.start_date&.to_formatted_s(:iso8601)
json.end plan.end_date&.to_formatted_s(:iso8601)

if plan.funder.present? || plan.grant_id.present?
  json.funding [plan] do
    json.partial! 'api/v2/plans/funding', plan: plan
  end
end
