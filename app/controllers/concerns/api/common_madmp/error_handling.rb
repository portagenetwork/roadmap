# frozen_string_literal: true

module Api
  module CommonMadmp
    # Handles errors raised by the API and renders them as API error responses.
    module ErrorHandling
      extend ActiveSupport::Concern

      included do
        rescue_from StandardError, with: :handle_exception
        rescue_from Doorkeeper::Errors::DoorkeeperError, with: :handle_doorkeeper_exception
      end

      private

      def render_error(error_code:, error_message:, status:)
        @error_code = error_code
        @error_message = error_message

        render '/api/common_madmp/error', status: status
      end

      def handle_doorkeeper_exception(exception)
        case exception
        when Doorkeeper::Errors::TokenForbidden, Doorkeeper::Errors::InvalidScope
          head :forbidden
        else
          authentication_required_error
        end
      end

      def authentication_required_error
        render_error(
          error_code: 'authentication_required',
          error_message: _('Authentication required to perform the specified request.'),
          status: :unauthorized
        )
      end

      def handle_exception(exception)
        if exception.is_a?(Pundit::NotAuthorizedError)
          handle_client_not_authorized
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

      def handle_client_not_authorized
        render_error(errors: _('The client is not authorized to perform this action.'), status: :forbidden)
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
