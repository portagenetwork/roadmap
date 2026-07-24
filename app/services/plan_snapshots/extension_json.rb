# frozen_string_literal: true

module PlanSnapshots
  # Accessor/wrapper for PlanSnapshot.extension_json.
  #
  # The underlying JSON payload contains DMPRoadmap-specific extension data:
  # - Template metadata
  # - Complete plan question/answer data
  class ExtensionJson
    def initialize(extension_json:)
      @extension_json = extension_json
    end

    def template
      @template ||= Template.new(extension_hash.dig('dmproadmap', 'template'))
    end

    def complete_plan
      @complete_plan ||= Array(extension_hash['complete_plan']).map do |item|
        CompletePlanItem.new(item)
      end
    end

    private

    attr_reader :extension_json

    def extension_hash
      extension = Array(extension_json&.dig('extension')).first
      extension.is_a?(Hash) ? extension : {}
    end

    # Wraps dmproadmap.template
    class Template
      def initialize(hash)
        @hash = hash.is_a?(Hash) ? hash : {}
      end

      def id
        hash['id']
      end

      def title
        hash['title']
      end

      private

      attr_reader :hash
    end

    # Wraps entries in extension.complete_plan
    class CompletePlanItem
      def initialize(hash)
        @hash = hash.is_a?(Hash) ? hash : {}
      end

      def title
        hash['title']
      end

      def answer
        hash['answer']
      end

      def section
        hash['section']
      end

      def question
        hash['question']
      end

      def question_id
        hash['question_id']
      end

      private

      attr_reader :hash
    end
  end
end
