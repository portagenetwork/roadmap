# frozen_string_literal: true

# locals: cost

json.title sanitize(cost[:title])
json.description cost[:description]
json.currency_code cost[:currency_code]
json.value sanitize(cost[:value])
