# frozen_string_literal: true

module Api 
  module V2 
    class PlansController < BaseApiController
      respond_to :json 

      # GET /api/v2/plans/:id
      def show
        unless @scopes.include?('read')
          raise Pundit::NotAuthorizedError
        end

        @plan = Plan.find_by(id: params[:id])

        unless @plan.present?
          raise Pundit::NotAuthorizedError
        end

        plans_policy = PlansPolicy.new(@resource_owner, @plan)
        unless plans_policy.show?
          raise Pundit::NotAuthorizedError
        end

        @items = [@plan]
        render '/api/v2/plans/index', status: :ok
      end

      # GET /api/v2/plans
      def index
        unless @scopes.include?('read')
          raise Pundit::NotAuthorizedError
        end

        @plans = PlansPolicy::Scope.new(@resource_owner).resolve
        @items = paginate_response(results: @plans)
        render '/api/v2/plans/index', status: :ok

      end
    end
  end
end