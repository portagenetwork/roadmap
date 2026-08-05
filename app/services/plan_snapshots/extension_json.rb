# frozen_string_literal: true

module PlanSnapshots
  # Accessor/wrapper for PlanSnapshot.extension_json.
  #
  # The underlying JSON payload contains a single top-level "template" key
  # describing the plan's template, phases, sections, questions, and answers.
  class ExtensionJson
    def initialize(extension_json:)
      @extension_json = extension_json
    end

    def template
      @template ||= Template.new(extension_hash['template'])
    end

    private

    attr_reader :extension_json

    def extension_hash
      extension_json.is_a?(Hash) ? extension_json : {}
    end

    # Wraps template
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

      def version
        hash['version']
      end

      def phases
        @phases ||= Array(hash['phases']).map { |phase| Phase.new(phase) }
      end

      private

      attr_reader :hash
    end

    # Wraps template.phases entries
    class Phase
      def initialize(hash)
        @hash = hash.is_a?(Hash) ? hash : {}
      end

      def title
        hash['title']
      end

      def number
        hash['number']
      end

      def sections
        @sections ||= Array(hash['sections']).map { |section| Section.new(section) }
      end

      private

      attr_reader :hash
    end

    # Wraps template.phases.sections entries
    class Section
      def initialize(hash)
        @hash = hash.is_a?(Hash) ? hash : {}
      end

      def title
        hash['title']
      end

      def number
        hash['number']
      end

      def modifiable
        hash['modifiable']
      end

      def questions
        @questions ||= Array(hash['questions']).map { |question| Question.new(question) }
      end

      private

      attr_reader :hash
    end

    # Wraps template.phases.sections.questions entries
    class Question
      def initialize(hash)
        @hash = hash.is_a?(Hash) ? hash : {}
      end

      def id
        hash['id']
      end

      def number
        hash['number']
      end

      def text
        hash['text']
      end

      def format
        return nil unless hash['format'].is_a?(Hash)

        @format ||= Format.new(hash['format'])
      end

      def answer
        @answer ||= Answer.new(hash['answer'])
      end

      private

      attr_reader :hash
    end

    # Wraps question.format
    class Format
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

    # Wraps question.answer
    class Answer
      def initialize(hash)
        @hash = hash.is_a?(Hash) ? hash : {}
      end

      def text
        hash['text']
      end

      def question_options
        @question_options ||= Array(hash['question_options']).map { |option| Option.new(option) }
      end

      private

      attr_reader :hash
    end

    # Wraps answer.question_options entries
    class Option
      def initialize(hash)
        @hash = hash.is_a?(Hash) ? hash : {}
      end

      def id
        hash['id']
      end

      def text
        hash['text']
      end

      private

      attr_reader :hash
    end
  end
end
