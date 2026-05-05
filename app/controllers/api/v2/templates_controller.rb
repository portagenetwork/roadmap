# frozen_string_literal: true

module Api
  module V2
    # provides a list of templates for API V2
    class TemplatesController < BaseApiController
      respond_to :json

      # GET /api/v2/templates/:id
      def show
        template = templates_scope.find_by(id: params[:id])

        return render_error(errors: [_('Template not found')], status: :not_found) unless template

        @items = [template]
        @total_items = 1
        render '/api/v2/templates/index', status: :ok
      end

      # GET /api/v2/templates
      def index
        @items = paginate_response(results: templates_scope)
        render '/api/v2/templates/index', status: :ok
      end

      private

      def templates_scope
        Api::V2::TemplatesPolicy::Scope.new(@resource_owner).resolve
      end
    end
  end
end
