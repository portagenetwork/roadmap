# frozen_string_literal: true

module Api
  module V2
    module Serialization
      # Renders the dmproadmap extension payload using the existing Jbuilder view.
      # This data supplements the RDA Common Standard payload stored in extension_json.
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
