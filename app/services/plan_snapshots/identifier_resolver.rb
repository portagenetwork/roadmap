# frozen_string_literal: true

module PlanSnapshots
  # Resolves a display identifier for snapshot listings/exports.
  class IdentifierResolver
    Result = Struct.new(:identifier, :type, keyword_init: true)

    class << self
      def call(plan:, snapshot:)
        new(plan: plan, snapshot: snapshot).call
      end
    end

    def initialize(plan:, snapshot:)
      @plan = plan
      @snapshot = snapshot
    end

    def call
      if snapshot.doi.present?
        Result.new(identifier: snapshot.doi, type: 'doi')
      else
        Result.new(identifier: version_url, type: 'url')
      end
    end

    private

    attr_reader :plan, :snapshot

    def version_url
      Rails.application.routes.url_helpers.plan_snapshot_url(plan, snapshot)
    end
  end
end
