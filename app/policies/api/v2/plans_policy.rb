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
        @plan.roles.where(user_id: @resource_owner.id, active: true).exists?
      end

      class Scope < Scope # rubocop:todo Style/Documentation
        def initialize(resource_owner) # rubocop:todo Lint/MissingSuper
          @resource_owner = resource_owner
        end

        def resolve
          Plan.joins(
            :roles
          ).includes(
            :identifiers,
            :research_outputs,
            :template,
            funder: :identifiers,
            contributors: [:identifiers, { org: :identifiers }],
            org: %i[region identifiers],
            roles: [user: [:identifiers, { org: :identifiers }]]
          )
              .where(roles: { user_id: @resource_owner.id, active: true })
              .distinct
        end
      end
    end
  end
end
