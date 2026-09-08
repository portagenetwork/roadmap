# frozen_string_literal: true

module Api
  module CommonMadmp
    # Handles errors raised by the API and renders them as API error responses.
    module ErrorHandling
      extend ActiveSupport::Concern

      included do
        rescue_from StandardError, with: :handle_exception
      end

      private

      # The Common MaDMP base controller overrides doorkeeper_render_error to
      # customize only the authentication-required response. Other Doorkeeper errors
      # continue to use the default behavior from the gem.
      def authentication_required_error
        response.headers['WWW-Authenticate'] =
          "Bearer realm=\"Doorkeeper\", error=\"invalid_token\", error_description=\"#{doorkeeper_error_description}\""

        render_error(error_code: 'authentication_required',
                     error_message: 'Authentication required to perform the specified request.',
                     status: :unauthorized)
      end

      def doorkeeper_error_description
        doorkeeper_error&.description || 'The access token is invalid'
      end

      def render_error(error_code:, error_message:, status:)
        @error_code = error_code
        @error_message = error_message

        render '/api/common_madmp/error', status: status
      end

      def insufficient_permissions_error
        render_error(
          error_code: 'insufficient_permissions',
          error_message: _('The authenticated client does not have permission to access the requested resource.'),
          status: :forbidden
        )
      end

      def handle_exception(exception)
        if exception.is_a?(Pundit::NotAuthorizedError)
          insufficient_permissions_error
        elsif exception.is_a?(ActionDispatch::Http::Parameters::ParseError) || exception.is_a?(JSON::ParserError)
          handle_json_parse_error(exception)
        else
          handle_internal_server_error(exception)
        end
      end

      def handle_internal_server_error(exception)
        # log server errors
        Rails.logger.error "Exception message: #{exception.message}"
        Rails.logger.error exception.backtrace.join("\n") if exception.backtrace.present?

        # inform client of server error
        render_error(errors: _('There was a problem in the server.'), status: :internal_server_error)
      end

      def handle_json_parse_error(exception)
        Rails.logger.error "Request parsing error: #{exception.message}"
        details = if exception.message.include?('unexpected token')
                    {
                      error_code: 'invalid_json',
                      hint: _('Check for malformed JSON (for example, unescaped quotes inside string values).')
                    }
                  end
        render_error(errors: _('Invalid JSON format'),
                     status: :bad_request,
                     details: details)
      end
    end
  end
end
