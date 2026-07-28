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

    def contact
      @contact ||= Contact.new(dmp_hash['contact'])
    end

    def contributors
      @contributors ||= Contributors.new(dmp_hash['contributor'])
    end

    def description
      dmp_hash['description']
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
      @dmp_hash ||= begin
        dmp = rda_json.is_a?(Hash) ? rda_json['dmp'] : nil
        dmp.is_a?(Hash) ? dmp : {}
      end
    end

    def project_hash
      p = Array(dmp_hash['project']).first
      p.is_a?(Hash) ? p : {}
    end

    # Wraps dmp.contact
    class Contact
      def initialize(hash)
        @hash = hash.is_a?(Hash) ? hash : {}
      end

      def affiliation
        @affiliation ||= Affiliation.new(hash['affiliation'])
      end

      def mbox
        hash['mbox']
      end

      def name
        hash['name']
      end

      private

      attr_reader :hash
    end

    # Wraps dmp.contributor[]
    class Contributors
      include Enumerable

      # NOTE: `::` is used here to prevent Ruby from resolving to the
      # PlanSnapshots::RdaJson::Contributor sibling
      ROLE_BASE_URL = ::Contributor::ONTOLOGY_BASE_URL
      ROLE_URIS = {
        data_curation: "#{ROLE_BASE_URL}data-curation",
        investigation: "#{ROLE_BASE_URL}investigation",
        project_administration: "#{ROLE_BASE_URL}project-administration",
        other: 'other'
      }.freeze

      def initialize(contributors)
        @contributors = Array(contributors).map { |c| Contributor.new(c) }
      end

      def each(&)
        contributors.each(&)
      end

      def with_role(role_key)
        uri = ROLE_URIS.fetch(role_key) { raise ArgumentError, "unknown role: #{role_key.inspect}" }
        contributors.select { |c| c.has_role?(uri) }
      end

      private

      attr_reader :contributors
    end

    # Wraps a single element in dmp.contributor[]
    class Contributor
      def initialize(hash)
        @hash = hash.is_a?(Hash) ? hash : {}
      end

      def affiliation
        @affiliation ||= Affiliation.new(hash['affiliation'])
      end

      def contributor_id
        @contributor_id ||= Identifier.new(hash['contributor_id'])
      end

      def name
        hash['name']
      end

      def role
        hash['role']
      end

      def has_role?(uri) # rubocop:disable Naming/PredicateName
        Array(role).include?(uri)
      end

      private

      attr_reader :hash
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

      def funding
        @funding ||= Funding.new(funding_hash)
      end

      private

      def funding_hash
        f = Array(hash['funding']).first
        f.is_a?(Hash) ? f : {}
      end

      attr_reader :hash
    end

    # Wraps the first entry of dmp.project.first.funding[]
    class Funding
      def initialize(hash)
        @hash = hash.is_a?(Hash) ? hash : {}
      end

      def name
        hash['name']
      end

      def grant_id
        @grant_id ||= Identifier.new(hash['grant_id'])
      end

      private

      attr_reader :hash
    end

    # Wraps any RDA affiliation object
    # JSON in app/views/api/v2/orgs/_show.json.jbuilder).
    class Affiliation
      def initialize(hash)
        @hash = hash.is_a?(Hash) ? hash : {}
      end

      def name
        hash['name']
      end

      private

      attr_reader :hash
    end
  end
end
