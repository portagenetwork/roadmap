# frozen_string_literal: true

module Api
  module V2
    module Serialization
      # Renders the API v2 plan payload using the existing Jbuilder view.
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
