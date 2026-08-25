# frozen_string_literal: true

module Api
  module CommonMadmp
    # Controller for the RDA Common MADMP API.
    class PlansController < BaseApiController
      POLICY = Api::V2::PlansPolicy
      # GET /dmps/:id
      def show
        @plan = plans_scope.find_by(id: params[:id])

        return dmp_not_found_error unless plans_policy(@plan).show?

        response.headers['Last-Modified'] = @plan.updated_at.httpdate

        render '/api/common_madmp/dmps/show', status: :ok
      end

      # GET /dmps
      def index
        @plans = plans_scope
        @items = paginate_response(results: @plans)
        render '/api/common_madmp/dmps/index', status: :ok
      end

      private

      def plans_scope
        POLICY::Scope.new(@resource_owner).resolve
      end

      def plans_policy(plan)
        POLICY.new(@resource_owner, plan)
      end

      def dmp_not_found_error
        render_error(
          error_code: 'dmp_not_found',
          error_message: _('Plan not found'),
          status: :not_found
        )
      end
    end
  end
end
