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

      def handle_doorkeeper_exception(exception)
        case exception
        when Doorkeeper::Errors::TokenForbidden, Doorkeeper::Errors::InvalidScope
          head :forbidden
        else
          authentication_required_error
        end
      end

      def handle_json_parse_error(exception)
        Rails.logger.error "Request parsing error: #{exception.message}"
        invalid_query_string_error(error_message: _('Invalid JSON format'))
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
        Rails.logger.error "Exception message: #{exception.message}"
        Rails.logger.error exception.backtrace.join("\n") if exception.backtrace.present?

        internal_server_error
      end

      def authentication_required_error
        render_error(
          error_code: 'authentication_required',
          error_message: _('Authentication required to perform the specified request.'),
          status: :unauthorized
        )
      end

      def insufficient_permissions_error
        render_error(
          error_code: 'insufficient_permissions',
          error_message: _('The authenticated client does not have permission to access the requested resource.'),
          status: :forbidden
        )
      end

      def invalid_query_string_error(error_message:)
        render_error(
          error_code: 'invalid_query_string',
          error_message: error_message,
          status: :bad_request
        )
      end

      def internal_server_error
        render_error(
          error_code: 'internal_server_error',
          error_message: _('There was a problem in the server.'),
          status: :internal_server_error
        )
      end

      def render_error(error_code:, error_message:, status:)
        @error_code = error_code
        @error_message = error_message

        render '/api/common_madmp/error', status: status
      end
    end
  end
end
