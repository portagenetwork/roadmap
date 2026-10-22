# frozen_string_literal: true

module Api
  module CommonMadmp
    module Helpers
      def expect_authentication_required_response
        expect_doorkeeper_unauthorized

        json = JSON.parse(response.body).with_indifferent_access
        expect(json[:error_code]).to eq('authentication_required')
        expect(json[:error_message]).to eq('Authentication required to perform the specified request.')
      end
    end
  end
end
