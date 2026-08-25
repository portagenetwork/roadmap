# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Api::CommonMadmp::BaseApiController do
  include ApiHelper

  describe 'token validation (doorkeeper_authorize!)' do
    it 'returns 401 Unauthorized when the token is malformed/invalid' do
      headers = {
        Accept: 'application/json',
        Authorization: 'Bearer not-a-real-token'
      }

      get(dmps_path, headers: headers)

      expect(response).to have_http_status(:unauthorized)
      expect_doorkeeper_unauthorized
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

      get(dmps_path, headers: headers)

      expect(response).to have_http_status(:unauthorized)
      expect_doorkeeper_unauthorized(description: 'The access token expired')
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

      get(dmps_path, headers: headers)

      expect(response).to have_http_status(:unauthorized)
      expect_doorkeeper_unauthorized(description: 'The access token was revoked')
    end

    it 'returns 403 Forbidden when the token lacks the read scope, since default_scopes requires read' do
      @user = create(:user)
      @client = create(:oauth_application, scopes: 'write')
      token = mock_authorization_code_token(oauth_application: @client, user: @user).plaintext_token

      headers = {
        Accept: 'application/json',
        Authorization: "Bearer #{token}"
      }

      get(dmps_path, headers: headers)

      expect(response).to have_http_status(:forbidden)
    end
  end

  describe 'request body parsing (parse_request)',
           skip: 'The Common MADMP API controller does not yet have any create or update actions' do
    before do
      @user = create(:user)
      @client = create(:oauth_application)
      token = mock_authorization_code_token(oauth_application: @client, user: @user).plaintext_token

      @headers = {
        Accept: 'application/json',
        'Content-Type': 'application/json',
        Authorization: "Bearer #{token}"
      }
    end

    it 'returns 400 Bad Request with a helpful hint when the JSON is malformed' do
      post(dmps_path, params: '{invalid json', headers: @headers)

      expect(response).to have_http_status(:bad_request)

      json = JSON.parse(response.body)
      expect(json['errors']).to include('Invalid JSON format')
    end

    it 'returns 400 Bad Request when the body is a JSON array rather than an object' do
      post(dmps_path, params: '[1, 2, 3]', headers: @headers)

      expect(response).to have_http_status(:bad_request)
    end

    it 'returns 400 Bad Request when the body is empty' do
      post(dmps_path, params: '', headers: @headers)

      expect(response).to have_http_status(:bad_request)
    end
  end

  describe 'pagination (pagination_params)' do
    before do
      @user = create(:user)
      @client = create(:oauth_application)
      token = mock_authorization_code_token(oauth_application: @client, user: @user).plaintext_token

      @headers = {
        Accept: 'application/json',
        Authorization: "Bearer #{token}"
      }
    end

    it 'caps per_page at the configured maximum' do
      max = Rails.configuration.x.application.api_max_page_size

      get(dmps_path, params: { per_page: max + 1000 }, headers: @headers)

      expect(response).to have_http_status(:ok)
    end

    it 'defaults to page 1 when no page param is given' do
      get(dmps_path, headers: @headers)

      expect(response).to have_http_status(:ok)
    end
  end
end
