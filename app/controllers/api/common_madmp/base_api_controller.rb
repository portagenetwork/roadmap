# frozen_string_literal: true

module Api
  module CommonMadmp
    class BaseApiController < ApplicationController # rubocop:todo Style/Documentation
      include Api::CommonMadmp::ErrorHandling
      include Api::CommonMadmp::Pagination
      # skipping the standard rails authenticity tokens passed in the UI
      skip_before_action :verify_authenticity_token

      before_action :doorkeeper_authorize!, except: %i[heartbeat]
      # Authorize resource owner, check if the user account associated with the token is active
      before_action :authorize_resource_owner, except: %i[heartbeat]
      # get details of server (e.g. DMPonline) and client app
      before_action :base_response_content

      before_action :log_access

      # controller can respond to json format requests
      respond_to :json

      # set up pages in response
      before_action :pagination_params, except: %i[heartbeat]

      # Parse the incoming JSON
      before_action :parse_request, only: %i[create update]

      private

      # define instance variable json and associated getter and setter methods
      attr_accessor :json

      def authorize_resource_owner
        return unless doorkeeper_token&.resource_owner_id.present?

        @resource_owner = User.find_by(id: doorkeeper_token.resource_owner_id)

        return if @resource_owner.present? && @resource_owner.active?

        insufficient_permissions_error
      end

      def base_response_content
        @application = ApplicationService.application_name
        @client = doorkeeper_token&.application
        @caller = @client&.name || request.remote_ip
      end

      def log_access
        if @client.present?
          Rails.logger.info "Client (OAuth) application name: #{@client.name}"
          Rails.logger.info "Client (OAuth) application uid: #{@client.uid}"
        end
        Rails.logger.info "Resource owner id: #{@resource_owner.id}" if @resource_owner
      end

      # Parse the body of the incoming request
      def parse_request
        @json = JSON.parse(request.body.read)
        raise JSON::ParserError unless @json.is_a?(Hash) && @json.present?

        @json = @json.with_indifferent_access
      rescue JSON::ParserError => e
        handle_json_parse_error(e)
      end
    end
  end
end
