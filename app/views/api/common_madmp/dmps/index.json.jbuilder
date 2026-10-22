# frozen_string_literal: true

json.total_count @total_count || 0

json.items @items do |item|
  json.partial! 'api/common_madmp/dmps/dmp', plan: item
end
