# frozen_string_literal: true

module PlanSnapshots
  # Resolves a display identifier for snapshot listings/exports.
  class IdentifierResolver
    Result = Struct.new(:identifier, :type, keyword_init: true)

    class << self
      def call(snapshot:)
        new(snapshot: snapshot).call
      end
    end

    def initialize(snapshot:)
      @snapshot = snapshot
    end

    def call
      # TODO: Once snapshot DOI minting is implemented, resolve persisted
      #       snapshot identifiers (and type) before falling back to URL.
      Result.new(identifier: version_url, type: 'url')
    end

    private

    attr_reader :snapshot

    def version_url
      Rails.application.routes.url_helpers.plan_snapshot_url(snapshot.plan, snapshot)
    end
  end
end
