# frozen_string_literal: true

module Api
  module V2
    class BaseApiController < Api::BaseApiController # rubocop:todo Style/Documentation
      include Api::V2::ErrorHandling
      include Api::V2::Pagination

      # get details of server (e.g. DMPonline) and client app
      before_action :base_response_content

      # GET /api/v2/heartbeat
      def heartbeat
        render '/api/v2/heartbeat'
      end

      # GET /me.json - recommended for doorkeeper gem
      def me
        render json: @resource_owner.slice(:firstname, :surname, :email).merge(
          organisation: @resource_owner.org.name,
          language: @resource_owner.language&.name
        )
      end

      private

      def base_response_content
        @application = ApplicationService.application_name
        @client = doorkeeper_token&.application
        @caller = @client&.name || request.remote_ip
      end
    end
  end
end
