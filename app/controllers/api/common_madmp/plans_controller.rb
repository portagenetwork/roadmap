# frozen_string_literal: true

module Api
  module CommonMadmp
    # Controller for the RDA Common MADMP API.
    class PlansController < Api::V2::PlansController
      # GET /dmps/:id
      def show
        @plan = plans_scope.find_by(id: params[:id])

        plans_policy = Api::V2::PlansPolicy.new(@resource_owner, @plan)
        return render_error(errors: [_('Plan not found')], status: :not_found) unless plans_policy.show?

        @items = [@plan]
        @total_items = 1
        render '/api/v2/plans/index', status: :ok
      end

      # GET /dmps
      def index
        @plans = plans_scope
        @items = paginate_response(results: @plans)
        render '/api/v2/plans/index', status: :ok
      end
    end
  end
end
