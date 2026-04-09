# frozen_string_literal: true

module Api
  module V1
    # Handles CRUD operations for plans in API V1
    class PlansController < BaseApiController
      respond_to :json

      # GET /api/v1/plans/:id
      def show
        plans = Api::V1::PlansPolicy::Scope.new(client, Plan).resolve
                                           .where(id: params[:id]).limit(1)

        if plans.present? && plans.any?
          @items = paginate_response(results: plans)
          render '/api/v1/plans/index', status: :ok
        else
          render_error(errors: [_('Plan not found')], status: :not_found)
        end
      end

      # POST /api/v1/plans
      def create
        return render_error(errors: [_('Invalid JSON or empty payload')], status: :bad_request) if @json.blank?

        service = Api::Plans::CreateFromDmpService.new(
          json: @json,
          resource_owner: client
        )

        if service.call
          # Use the plan returned by the service for the response
          @items = paginate_response(results: Plan.where(id: service.plan.id))
          render '/api/v1/plans/index', status: :created
        else
          render_error(errors: service.errors, status: :bad_request)
        end
      rescue JSON::ParserError
        render_error(errors: [_('Invalid JSON')], status: :bad_request)
      end

      # GET /api/v1/plans
      def index
        # ALL can view: public
        # ApiClient can view: anything from the API client
        # User (non-admin) can view: any personal or organisationally_visible
        # User (admin) can view: all from users of their organisation
        plans = Api::V1::PlansPolicy::Scope.new(client, Plan).resolve
        if plans.present? && plans.any?
          @items = paginate_response(results: plans)
          @minimal = true
          render 'api/v1/plans/index', status: :ok
        else
          render_error(errors: [_('No Plans found')], status: :not_found)
        end
      end

      private

      def dmp_params
        params.require(:dmp).permit(plan_permitted_params).to_h
      end

      def plan_exists?(json:)
        return false unless json.present? &&
                            json[:dmp_id].present? &&
                            json[:dmp_id][:identifier].present?

        scheme = IdentifierScheme.by_name(json[:dmp_id][:type]).first
        Identifier.where(value: json[:dmp_id][:identifier], identifier_scheme: scheme).any?
      end
    end
  end
end
