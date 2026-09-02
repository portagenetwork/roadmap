# frozen_string_literal: true

json.partial! 'api/common_madmp/standard_response', total_count: @total_count

json.items @items do |item|
  json.partial! 'api/common_madmp/dmps/dmp', plan: item
end
