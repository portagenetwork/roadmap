# frozen_string_literal: true

module Api
  module V2
    module Serialization
      module PlanSnapshots
        # Serializes the RDA Common Standard payload for plan_snapshot.rda_json storage.
        #
        # Uses the existing API v2 plan Jbuilder view to ensure snapshot data
        # follows the same RDA structure as the API response.
        class RdaSerializer
          class << self
            def call(plan:)
              new(plan: plan).call
            end
          end

          def initialize(plan:)
            @plan = plan
          end

          def call
            payload = ApplicationController.renderer.render(
              partial: 'api/v2/plans/show',
              formats: [:json],
              locals: { plan: @plan },
              assigns: { rda_only: true }
            )

            { dmp: JSON.parse(payload) }
          end
        end
      end
    end
  end
end
