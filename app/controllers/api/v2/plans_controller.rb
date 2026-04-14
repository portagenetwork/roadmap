# frozen_string_literal: true

module Api
  module V2
    class PlansController < BaseApiController # rubocop:todo Style/Documentation
      respond_to :json
      before_action :set_complete_param, only: %i[show index]

      # If the Resource Owner (aka User) is in the Doorkeeper AccessToken then it is an authorization_code
      # token and we need to ensure that the OAuth application is authorized for the relevant Scope
      before_action -> { doorkeeper_authorize! :write }, only: %i[create update]

      # GET /api/v2/plans/:id
      def show
        @plan = plans_scope.find_by(id: params[:id])

        plans_policy = PlansPolicy.new(@resource_owner, @plan)
        raise Pundit::NotAuthorizedError unless plans_policy.show?

        @items = [@plan]
        render '/api/v2/plans/index', status: :ok
      end

      # GET /api/v2/plans
      def index
        @plans = plans_scope
        @items = paginate_response(results: @plans)
        render '/api/v2/plans/index', status: :ok
      end

      private

      # GET /api/v2/plans?complete=true and  /api/v2/plans/:id?complete=true
      def set_complete_param
        @complete = params[:complete].to_s.casecmp('true').zero?
      end

      def plans_scope
        scope = PlansPolicy::Scope.new(@resource_owner).resolve
        @complete ? scope.includes(answers: { question: :section }) : scope
      end
    end
  end
end
