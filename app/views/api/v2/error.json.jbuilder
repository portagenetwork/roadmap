# frozen_string_literal: true

json.partial! 'api/v2/standard_response'

json.items []
json.errors @payload[:errors] if @payload[:errors].present?
json.message @payload[:message]
json.details @payload[:details]
