# frozen_string_literal: true

json.id plan.id

json.dmp do
  json.partial! 'api/v2/plans/show', plan: plan
end
