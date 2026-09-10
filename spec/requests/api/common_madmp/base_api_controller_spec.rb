# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Api::CommonMadmp::BaseApiController do
  include ApiHelper
  include Api::CommonMadmp::Helpers

  describe 'token validation (doorkeeper_authorize!)' do
    it 'returns 401 Unauthorized when the token is malformed/invalid' do
      headers = {
        Accept: 'application/json',
        Authorization: 'Bearer not-a-real-token'
      }

      get(dmps_path, headers: headers)

      expect_authentication_required_error
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

      expect_authentication_required_error
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

      expect_authentication_required_error
    end

    it 'rejects a request when the token has the endpoint-specific permission but is missing the default read scope' do
      @user = create(:user)
      @client = create(:oauth_application, scopes: 'write')
      token = mock_authorization_code_token(oauth_application: @client, user: @user).plaintext_token
      plan = create(:plan, org: @user.org)
      plan.add_user!(@user.id, :creator)

      headers = {
        Accept: 'application/json',
        Authorization: "Bearer #{token}"
      }

      delete(dmp_path(plan), headers: headers)

      expect(response).to have_http_status(:forbidden)
      expect(response.body).to be_empty
    end

    it 'returns 403 Forbidden when the resource owner account is inactive' do
      @user = create(:user)
      @client = create(:oauth_application)
      token = mock_authorization_code_token(oauth_application: @client, user: @user).plaintext_token
      @user.update(active: false)

      headers = {
        Accept: 'application/json',
        Authorization: "Bearer #{token}"
      }

      get(dmps_path, headers: headers)

      expect(response).to have_http_status(:forbidden)
      expect(response.parsed_body).to eq(
        'error_code' => 'insufficient_permissions',
        'error_message' => 'The authenticated client does not have permission to access the requested resource.'
      )
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

  describe 'error handling' do
    before do
      @user = create(:user)
      @client = create(:oauth_application)
      token = mock_authorization_code_token(oauth_application: @client, user: @user).plaintext_token

      @headers = {
        Accept: 'application/json',
        Authorization: "Bearer #{token}"
      }
    end

    it 'returns an internal_server_error payload when an unexpected exception is raised' do
      described_class.any_instance.stubs(:pagination_params).raises(StandardError, 'boom')

      get(dmps_path, headers: @headers)

      expect(response).to have_http_status(:internal_server_error)

      json = JSON.parse(response.body)
      expect(json['error_code']).to eq('internal_server_error')
      expect(json['error_message']).to eq('There was a problem in the server.')
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

    it 'caps count at the configured maximum' do
      max = Rails.configuration.x.application.api_max_page_size

      get(dmps_path, params: { count: max + 1000 }, headers: @headers)

      expect(response).to have_http_status(:bad_request)

      json = JSON.parse(response.body)
      expect(json['error_code']).to eq('invalid_query_string')
    end

    it 'rejects invalid offset and count values' do
      get(dmps_path, params: { offset: '-1', count: '0' }, headers: @headers)

      expect(response).to have_http_status(:bad_request)

      json = JSON.parse(response.body)
      expect(json['error_code']).to eq('invalid_query_string')
      expect(json['error_message']).to eq('The query string contained invalid pagination parameters.')
    end

    it 'returns an invalid_query_string error for malformed numeric params' do
      get(dmps_path, params: { offset: 'abc', count: '5' }, headers: @headers)

      expect(response).to have_http_status(:bad_request)

      json = JSON.parse(response.body)
      expect(json['error_code']).to eq('invalid_query_string')
      expect(json['error_message']).to eq('The query string contained invalid pagination parameters.')
    end

    it 'accepts valid offset and count params' do
      create_list(:plan, 25, org: @user.org).each do |plan|
        plan.add_user!(@user.id, :creator)
      end

      get(dmps_path, params: { offset: '10', count: '5' }, headers: @headers)

      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json['page']).to eq(10)
      expect(json['per_page']).to eq(5)
    end
  end
end
