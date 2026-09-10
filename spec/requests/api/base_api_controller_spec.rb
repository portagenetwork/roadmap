# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Api::CommonMadmp::BaseApiController do
  include ApiHelper

  RSpec.shared_examples 'default API controller token validation' do |request_method:, request_path:,
                                                                        invalid_token_expectation:,
                                                                        expired_token_expectation:,
                                                                        revoked_token_expectation:|

    it 'returns 401 Unauthorized when the token is malformed/invalid' do
      headers = {
        Accept: 'application/json',
        Authorization: 'Bearer not-a-real-token'
      }

      send(request_method, instance_exec(&request_path), headers: headers)

      instance_exec(&invalid_token_expectation)
    end

    it 'returns 401 Unauthorized when the token has expired' do
      @user = create(:user)
      @client = create(:oauth_application)
      token = mock_authorization_code_token(
        oauth_application: @client, user: @user, expires_in: -1
      ).plaintext_token

      headers = {
        Accept: 'application/json',
        Authorization: "Bearer #{token}"
      }

      send(request_method, instance_exec(&request_path), headers: headers)

      instance_exec(&expired_token_expectation)
    end

    it 'returns 401 Unauthorized when the token has been revoked' do
      @user = create(:user)
      @client = create(:oauth_application)
      access_token = mock_authorization_code_token(oauth_application: @client, user: @user)
      access_token.revoke
      token = access_token.plaintext_token

      headers = {
        Accept: 'application/json',
        Authorization: "Bearer #{token}"
      }

      send(request_method, instance_exec(&request_path), headers: headers)

      instance_exec(&revoked_token_expectation)
    end
  end

  RSpec.shared_examples 'default API controller default-scope enforcement' do |request_method:,
                                                                               request_path:,
                                                                               request_params: {},
                                                                               request_setup: nil|
    it 'rejects a request when the token has the endpoint-specific permission but is missing the default read scope' do
      @user = create(:user)
      @client = create(:oauth_application, scopes: 'write')
      token = mock_authorization_code_token(oauth_application: @client, user: @user).plaintext_token

      instance_exec(&request_setup) if request_setup.present?

      headers = {
        Accept: 'application/json',
        Authorization: "Bearer #{token}"
      }

      send(request_method, instance_exec(&request_path), params: request_params, headers: headers)

      expect(response).to have_http_status(:forbidden)
      expect(response.body).to be_empty
    end
  end
end
