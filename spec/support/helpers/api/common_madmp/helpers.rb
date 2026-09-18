# frozen_string_literal: true

module Api
  module CommonMadmp
    module Helpers
      def expect_authentication_required_error
        expect(response).to have_http_status(:unauthorized)
        expect(response.parsed_body).to eq(
          'error_code' => 'authentication_required',
          'error_message' => 'Authentication required to perform the specified request.'
        )
      end
    end
  end
end
