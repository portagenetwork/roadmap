# frozen_string_literal: true

module Api
  module CommonMadmp
    # Controller for the RDA Common MADMP API.
    class PlansController < BaseApiController
      include Api::CommonMadmp::Filtering
      include Api::CommonMadmp::Sorting

      POLICY = Api::V2::PlansPolicy

      # GET /api/madmp/dmps/:id
      def show
        @plan = plans_scope.find_by(id: params[:id])

        return dmp_not_found_error unless plans_policy(@plan).show?

        response.headers['Last-Modified'] = @plan.updated_at.httpdate

        render '/api/common_madmp/dmps/show', status: :ok
      end

      # GET /api/madmp/dmps
      def index
        @plans = plans_scope
        @plans = apply_filters(@plans)
        return if performed?

        @plans = apply_sorting(@plans)
        return if performed?

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
