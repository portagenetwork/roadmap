# frozen_string_literal: true

json.partial! 'api/v2/standard_response'

json.items [] # TODO: This line is commented out in DMPRoadmap
json.errors @payload[:errors]
json.details @payload[:details]
