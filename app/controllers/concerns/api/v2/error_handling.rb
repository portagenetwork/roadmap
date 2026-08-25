# frozen_string_literal: true

module Api
  module V2
    # Handles errors raised by the API and renders them as API error responses.
    module ErrorHandling
      extend ActiveSupport::Concern
      include Api::DoorkeeperExceptionHandling

      included do
        rescue_from StandardError, with: :handle_exception
        rescue_from Doorkeeper::Errors::DoorkeeperError, with: :handle_doorkeeper_exception
      end

      private

      def render_error(errors:, status:, details: nil)
        @payload = { errors: errors, details: details }
        render '/api/v2/error', status: status
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
