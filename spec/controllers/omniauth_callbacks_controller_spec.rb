# frozen_string_literal: true

require 'rails_helper'
require 'byebug'

RSpec.describe Users::OmniauthCallbacksController, type: :controller do
  before do
    # Enable test mode for OmniAuth
    OmniAuth.config.test_mode = true

    # Setup Devise mapping
    @request.env["devise.mapping"] = Devise.mappings[:user]
    create(:org, managed: false, is_other: true)
    @org = create(:org, managed: true)
    @identifier_scheme = create(:identifier_scheme,
                                name: 'openid_connect',
                                description: 'CILogon',
                                active: true,
                                identifier_prefix: 'https://www.cilogon.org/')

    # Mock OmniAuth data for OpenID Connect with necessary info
    OmniAuth.config.mock_auth[:openid_connect] = OmniAuth::AuthHash.new({
      provider: 'openid_connect',
      uid: '12345',
      info: {
        email: 'test@example.com',
        first_name: 'Test',
        last_name: 'User',
        name: 'Test User'
      }
    })

    # Assign the mocked authentication hash to the request environment
    @request.env["omniauth.auth"] = OmniAuth.config.mock_auth[:openid_connect]
  end

  describe 'GET #openid_connect' do
    let(:auth) { request.env['omniauth.auth'] }
    let!(:identifier_scheme) { IdentifierScheme.create(name: auth.provider) }

    context 'when the email is missing and the user does not exist' do
      before do
        # Simulate missing email
        OmniAuth.config.mock_auth[:openid_connect].info.email = nil
        @request.env["omniauth.auth"] = OmniAuth.config.mock_auth[:openid_connect]

        def User.from_omniauth(_auth)
          nil
        end
      end

      it 'redirects to the registration page with a flash message' do
        get :openid_connect

        expect(response).to redirect_to(new_user_registration_path)
        expect(flash[:notice]).to eq('Something went wrong, Please try signing-up here.')
      end
    end

    context 'when the user is not signed in but already exists' do
      # let!(:user) { User.create(email: auth.info.email, password: 'password123') }
      let!(:user) { User.create(email: 'test@example.com', firstname: 'Test', surname: 'User',  org: @org) }

      before do
        def User.from_omniauth(_auth)
          User.find_by(email: 'test@example.com')
        end

        def IdentifierScheme.find_by_name(provider_name)
          IdentifierScheme.find_by(name: provider_name)
        end
      end

      it 'signs in the existing user' do
        get :openid_connect
        # expect(subject.current_user).to eq(user)
        expect(response).to redirect_to(root_path)
        expect(flash[:notice]).to be_nil
      end
    end

    context 'when the user is signed in and needs to link their OpenID Connect account' do
      let!(:user) {  User.create(email: 'test@example.com', firstname: 'Test', surname: 'User',  org: @org) }

      before do
        sign_in user

        def User.from_omniauth(_auth)
          nil
        end

        def IdentifierScheme.find_by_name(provider_name)
          IdentifierScheme.find_by(name: provider_name)
        end
      end

      # it 'links the user account and redirects to root_path' do
      #   expect {
      #     get :openid_connect
      #   }.to change(user.identifiers, :count).by(1)
      #   expect(response).to redirect_to(root_path)
      #   expect(flash[:notice]).to eq('Linked succesfully')
      # end
    end

    context 'when an unknown error occurs' do
      before do
        def User.from_omniauth(_auth)
          raise StandardError.new('Unexpected error')
        end
      end

      it 'handles the error and raises an exception' do
        expect {
          get :openid_connect
        }.to raise_error(StandardError, 'Unexpected error')
      end
    end
  end
end
