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
      @dmp_id ||= Identifier.new(dmp_hash['dmp_id'])
    end

    def project
      @project ||= Project.new(project_hash)
    end

    def title
      dmp_hash['title']
    end

    private

    attr_reader :rda_json

    def dmp_hash
      dmp = rda_json&.dig('dmp')
      dmp.is_a?(Hash) ? dmp : {}
    end

    def project_hash
      p = Array(dmp_hash['project']).first
      p.is_a?(Hash) ? p : {}
    end

    # Wraps any RDA { type, identifier } pair
    class Identifier
      def initialize(hash)
        @hash = hash.is_a?(Hash) ? hash : {}
      end

      def identifier
        hash['identifier']
      end

      def type
        hash['type']
      end

      private

      attr_reader :hash
    end

    # Wraps the first entry of dmp.project
    class Project
      def initialize(hash)
        @hash = hash.is_a?(Hash) ? hash : {}
      end

      def start_date
        hash['start']
      end

      def end_date
        hash['end']
      end

      private

      attr_reader :hash
    end
  end
end
