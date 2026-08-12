# frozen_string_literal: true

module Api
  module V2
    module Serialization
      module PlanSnapshots
        # Serializes the extension JSON payload stored with a plan snapshot.
        #
        # Uses a snapshot-specific Jbuilder view to generate the template
        # hierarchy and answers required to recreate snapshot exports.
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
            presenter = Api::V2::PlanSnapshotPresenter.new(plan: @plan)

            payload = ApplicationController.renderer.render(
              partial: 'api/v2/plan_snapshots/extension',
              formats: [:json],
              locals: { presenter: presenter }
            )

            JSON.parse(payload)
          end
        end
      end
    end
  end
end
