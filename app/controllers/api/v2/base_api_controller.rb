# frozen_string_literal: true

module Api
  module V2
    class BaseApiController < Api::BaseApiController # rubocop:todo Style/Documentation
      include Api::V2::ErrorHandling
      include Api::V2::Pagination

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
    end
  end
end
