# frozen_string_literal: true

module Api
  # Shared BaseApiController for both the CommonMadmp and V2 APIs
  class BaseApiController < ApplicationController
    skip_before_action :verify_authenticity_token
    before_action :doorkeeper_authorize!, except: %i[heartbeat]
    before_action :authorize_resource_owner, except: %i[heartbeat]
    before_action :log_access
    before_action :require_read_scope, except: %i[heartbeat me]

    respond_to :json

    before_action :pagination_params, only: %i[index]
    before_action :parse_request, only: %i[create update]

    private

    attr_accessor :json

    def authorize_resource_owner
      return unless doorkeeper_token&.resource_owner_id.present?

      @resource_owner = User.find_by(id: doorkeeper_token.resource_owner_id)

      return if @resource_owner.present? && @resource_owner.active?

      handle_deactivated_resource_owner
    end

    def log_access
      client = doorkeeper_token&.application

      if client.present?
        Rails.logger.info "Client (OAuth) application name: #{client.name}"
        Rails.logger.info "Client (OAuth) application uid: #{client.uid}"
      end
      Rails.logger.info "Resource owner id: #{@resource_owner.id}" if @resource_owner
    end

    def require_read_scope
      raise Pundit::NotAuthorizedError unless doorkeeper_token.scopes.include?('read')
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
