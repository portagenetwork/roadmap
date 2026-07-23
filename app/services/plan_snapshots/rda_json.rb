# frozen_string_literal: true

module PlanSnapshots
  # Accessor/wrapper for PlanSnapshot.rda_json.
  #
  # The underlying JSON payload adheres to the RDA DMP Common Standard structure:
  # https://github.com/RDA-DMP-Common/RDA-DMP-Common-Standard#structure
  class RdaJson
    def initialize(rda_json:)
      @rda_json = rda_json
    end

    def dmp_id
      @dmp_id ||= Identifier.new(dmp_id_hash)
    end

    private

    attr_reader :rda_json

    def dmp_id_hash
      dmp_id = rda_json&.dig('dmp', 'dmp_id')
      return {}.with_indifferent_access unless dmp_id.is_a?(Hash)

      dmp_id.with_indifferent_access
    end

    # Wraps any RDA { type, identifier } pair
    class Identifier
      def initialize(hash)
        @hash = hash
      end

      def identifier
        hash[:identifier]
      end

      def type
        hash[:type]
      end

      private

      attr_reader :hash
    end
  end
end
