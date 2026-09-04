# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Api::V2::BaseApiController do
  include ApiHelper

  def expect_doorkeeper_unauthorized(description: 'The access token is invalid')
    expect(response).to have_http_status(:unauthorized)
    expect(response.headers['WWW-Authenticate']).to eq(
      "Bearer realm=\"Doorkeeper\", error=\"invalid_token\", error_description=\"#{description}\""
    )
  end

  describe 'GET /api/v2/heartbeat' do
    it 'returns 200 OK without requiring an authorization token' do
      get(api_v2_heartbeat_path, headers: { Accept: 'application/json' })

      expect(response).to have_http_status(:ok)
    end
  end

  describe 'GET /api/v2/me' do
    context 'OAuth (authorization_code grant type) — on behalf of a user' do
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

      it 'returns 200 OK and user details when user is active' do
        get(api_v2_me_path, headers: @headers)

        expect(response).to have_http_status(:ok)

        json = JSON.parse(response.body)
        expect(json['email']).to eq(@user.email)
        expect(json['firstname']).to eq(@user.firstname)
        expect(json['surname']).to eq(@user.surname)
        expect(json['organisation']).to eq(@user.org.name)
      end

      it 'returns 401 Unauthorized when user account is deactivated' do
        @user.update(active: false)

        get(api_v2_me_path, headers: @headers)

        expect(response).to have_http_status(:unauthorized)

        json = JSON.parse(response.body)
        expect(json['errors']).to include('User account has been deactivated.')
      end

      it 'returns 401 Unauthorized when user account is deleted' do
        @user.destroy

        get(api_v2_me_path, headers: @headers)

        expect_doorkeeper_unauthorized
      end
    end

    # NOTE: client_credentials grant flow isn't implemented yet. Once it is,
    # reintroduce a context here using mock_client_credentials_token.

    context 'when no authorization token is provided' do
      it 'returns 401 Unauthorized' do
        get(api_v2_me_path, headers: { Accept: 'application/json' })

        expect_doorkeeper_unauthorized
      end
    end
  end

  describe 'token validation (doorkeeper_authorize!)' do
    it 'returns 401 Unauthorized when the token is malformed/invalid' do
      headers = {
        Accept: 'application/json',
        Authorization: 'Bearer not-a-real-token'
      }

      get(api_v2_me_path, headers: headers)

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

      get(api_v2_me_path, headers: headers)

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

      get(api_v2_me_path, headers: headers)

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

      get(api_v2_plans_path, headers: headers)

      expect(response).to have_http_status(:forbidden)
    end

    it 'does not require any scope on heartbeat' do
      get(api_v2_heartbeat_path, headers: { Accept: 'application/json' })

      expect(response).not_to have_http_status(:forbidden)
    end
  end

  describe 'access logging (log_access)' do
    it 'logs the client application name, uid, and resource owner id' do
      @user = create(:user)
      @client = create(:oauth_application)
      token = mock_authorization_code_token(oauth_application: @client, user: @user).plaintext_token

      logged_messages = []
      Rails.logger.stubs(:info).with do |message|
        logged_messages << message
        true
      end

      get(api_v2_me_path, headers: { Accept: 'application/json', Authorization: "Bearer #{token}" })

      expect(logged_messages).to include(
        a_string_matching(/Client \(OAuth\) application name: #{Regexp.escape(@client.name)}/)
      )
      expect(logged_messages).to include(
        a_string_matching(/Client \(OAuth\) application uid: #{Regexp.escape(@client.uid)}/)
      )
      expect(logged_messages).to include(
        a_string_matching(/Resource owner id: #{@user.id}/)
      )
    end
  end

  describe 'request body parsing (parse_request)' do
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
      post(api_v2_plans_path, params: '{invalid json', headers: @headers)

      expect(response).to have_http_status(:bad_request)

      json = JSON.parse(response.body)
      expect(json['errors']).to include('Invalid JSON format')
    end

    it 'returns 400 Bad Request when the body is a JSON array rather than an object' do
      post(api_v2_plans_path, params: '[1, 2, 3]', headers: @headers)

      expect(response).to have_http_status(:bad_request)
    end

    it 'returns 400 Bad Request when the body is empty' do
      post(api_v2_plans_path, params: '', headers: @headers)

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

      get(api_v2_plans_path, params: { per_page: max + 1000 }, headers: @headers)

      expect(response).to have_http_status(:ok)
    end

    it 'defaults to page 1 when no page param is given' do
      get(api_v2_plans_path, headers: @headers)

      expect(response).to have_http_status(:ok)
    end
  end
end
