# frozen_string_literal: true

# Accessor/wrapper for PlanSnapshot.rda_json.
#
# The underlying JSON payload adheres to the RDA DMP Common Standard structure:
# https://github.com/RDA-DMP-Common/RDA-DMP-Common-Standard#structure
class PlanSnapshotRdaJson
  def initialize(rda_json:)
    @rda_json = rda_json
  end

  def identifier
    dmp_id_hash[:identifier]
  end

  def identifier_type
    dmp_id_hash[:type]
  end

  private

  attr_reader :rda_json

  def dmp_id_hash
    dmp_id = rda_json&.dig('dmp', 'dmp_id')
    return {}.with_indifferent_access unless dmp_id.is_a?(Hash)

    dmp_id.with_indifferent_access
  end
end
