# frozen_string_literal: true

module Api
  module V2
    # Security rules for API V2 Plan endpoints
    class PlansPolicy < ApplicationPolicy
      # overriding the initializer due to resource owner / user
      # not needing to be logged in for client app to make requests
      def initialize(resource_owner, plan = nil) # rubocop:todo Lint/MissingSuper
        @resource_owner = resource_owner
        @plan = plan
      end

      def show?
        @plan.present? && Plan.with_active_role_for(@resource_owner.id)
                              .exists?(id: @plan.id)
      end

      def update?
        @plan&.editable_by?(@resource_owner.id)
      end

      class Scope < Scope # rubocop:todo Style/Documentation
        def initialize(resource_owner) # rubocop:todo Lint/MissingSuper
          @resource_owner = resource_owner
        end

        # Eager loads all associations needed for API v2 serialization,
        # and restricts to plans where the user_id has an active role.
        # - (i.e. .where(roles: { user_id: @resource_owner.id, active: true }))
        def resolve
          Plan.for_api_v2(@resource_owner.id)
        end
      end
    end
  end
end
