# frozen_string_literal: true

module Paginable
  # Controller for paginating/sorting/searching the api_clients table
  class ApiClientsController < ApplicationController
    include Paginable

    after_action :verify_authorized

    # GET /paginable/api_clients
    def index
      authorize(ApiClient)
      @api_clients = ApiClient.all

      paginable_renderise(
        partial: 'index',
        scope: @api_clients,
        query_params: { sort_field: 'api_clients.name' },
        format: :json
      )
    end
  end
end
