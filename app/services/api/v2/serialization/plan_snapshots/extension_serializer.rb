# frozen_string_literal: true

module Api
  module V2
    module Serialization
      module PlanSnapshots
        # Serializes the  extension JSON payload for plan_snapshot.extension_json storage.
        #
        # Uses the existing API v2 plan extension Jbuilder view to ensure the
        # snapshot extension data remains consistent with the API representation.
        class ExtensionSerializer
          class << self
            def call(plan:)
              new(plan: plan).call
            end
          end

          def initialize(plan:)
            @plan = plan
          end

          def call
            presenter = Api::V2::PlanPresenter.new(plan: @plan, complete: true)

            payload = ApplicationController.renderer.render(
              partial: 'api/v2/plans/extension',
              formats: [:json],
              locals: { plan: @plan, presenter: presenter },
              assigns: { complete: true }
            )

            JSON.parse(payload)
          end
        end
      end
    end
  end
end
