# frozen_string_literal: true

json.id plan.id

json.dmp do
  json.partial! 'api/v2/plans/show',
                plan: plan,
                for_common_madmp_api: true
end
