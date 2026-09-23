# frozen_string_literal: true

module Api
  module CommonMadmp
    module Helpers
      def expect_authentication_required_response # rubocop:disable Metrics/AbcSize
        expect(response).to have_http_status(:unauthorized)
        expect(response.headers['WWW-Authenticate']).to eq(
          "Bearer realm=\"Doorkeeper\", error=\"invalid_token\", error_description=\"#{response_error_description}\""
        )

        json = JSON.parse(response.body).with_indifferent_access
        expect(json[:error_code]).to eq('authentication_required')
        expect(json[:error_message]).to eq('Authentication required to perform the specified request.')
      end

      private

      def response_error_description
        response.headers['WWW-Authenticate'].match(/error_description="([^"]+)"/)&.captures&.first ||
          'The access token is invalid'
      end
    end
  end
end
