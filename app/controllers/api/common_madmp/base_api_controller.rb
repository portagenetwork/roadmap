# frozen_string_literal: true

module Api
  module CommonMadmp
    # Base controller for the Common MaDMP API
    class BaseApiController < Api::BaseApiController
      include Api::CommonMadmp::ErrorHandling
      include Api::CommonMadmp::Pagination

      private

      # Doorkeeper exposes this hook so controllers can override the default rendering
      # behavior. We keep the default Doorkeeper response for non-auth failures, but
      # customize the authentication-required case to match the Common MaDMP API contract.
      def doorkeeper_render_error
        return authentication_required_error if doorkeeper_error.is_a?(Doorkeeper::OAuth::InvalidTokenResponse)

        super
      end
    end
  end
end
