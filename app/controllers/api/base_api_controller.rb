# frozen_string_literal: true

module Api
  class BaseApiController < ApplicationController # rubocop:todo Style/Documentation
    skip_before_action :verify_authenticity_token
    before_action :doorkeeper_authorize!, except: %i[heartbeat]
    before_action :authorize_resource_owner, except: %i[heartbeat]
    # get details of server (e.g. DMPonline) and client app
    before_action :base_response_content
    before_action :log_access

    respond_to :json

    before_action :pagination_params, except: %i[heartbeat]
    before_action :parse_request, only: %i[create update]

    private

    attr_accessor :json

    def authorize_resource_owner
      return unless doorkeeper_token&.resource_owner_id.present?

      @resource_owner = User.find_by(id: doorkeeper_token.resource_owner_id)

      return if @resource_owner.present? && @resource_owner.active?

      handle_deactivated_resource_owner
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

    def parse_request
      @json = JSON.parse(request.body.read)
      raise JSON::ParserError unless @json.is_a?(Hash) && @json.present?

      @json = @json.with_indifferent_access
    rescue JSON::ParserError => e
      handle_json_parse_error(e)
    end
  end
end
