# frozen_string_literal: true

module Api
  # Doorkeeper's `handle_auth_errors :raise` is enabled so that the Common
  # MaDMP API can handle authentication errors itself and conform to the API
  # specification. This concern centralizes Doorkeeper exception handling
  # while preserving Doorkeeper's default HTTP behaviour for the V2 API.
  #
  # Handling these exceptions here does not introduce a security risk or change
  # the authentication behaviour; it simply crafts the same HTTP responses
  # Doorkeeper would have returned before `handle_auth_errors :raise` was enabled.
  module DoorkeeperExceptionHandling
    extend ActiveSupport::Concern

    def handle_doorkeeper_exception(exception)
      case exception
      when Doorkeeper::Errors::TokenForbidden, Doorkeeper::Errors::InvalidScope
        head :forbidden
      when Doorkeeper::Errors::TokenExpired
        doorkeeper_unauthorized('The access token expired')
      when Doorkeeper::Errors::TokenRevoked
        doorkeeper_unauthorized('The access token was revoked')
      else
        # Most authentication errors inherit from InvalidToken (e.g. TokenUnknown),
        # so they share the standard invalid-token response. This also catches any
        # other Doorkeeper errors; add explicit cases above if they need different handling.
        doorkeeper_unauthorized('The access token is invalid')
      end
    end

    def doorkeeper_unauthorized(error_description)
      response.headers['WWW-Authenticate'] =
        "Bearer realm=\"Doorkeeper\", error=\"invalid_token\", error_description=\"#{error_description}\""

      head :unauthorized
    end
  end
end
