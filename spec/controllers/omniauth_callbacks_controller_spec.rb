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
      let(:current_user) { create(:user) }

      before do
        sign_in current_user

        # Ensure from_omniauth returns nil, indicating no user is associated with the auth
        User.define_singleton_method(:from_omniauth) do |_auth|
          nil
        end
      end

      it "links identifier to current user, sets flash notice, and redirects to root path" do
        expect {
          get :openid_connect
          current_user.reload # Ensure we have the latest state of the user
        }.to change(current_user.identifiers, :count).by(1)

        expect(flash[:notice]).to eq('Linked successfully')
        expect(response).to redirect_to(root_path)
      end
    end

    context 'when the user found via omniauth is different from the current_user' do
      let(:current_user) { create(:user) }
      let!(:different_user) { create(:user, email: 'different_user@example.com') } # Ensure different_user is created before test runs

      before do
        sign_in current_user

        # Mocking the from_omniauth method to return a different user
        # We use `let!` to ensure `different_user` is accessible here
        User.define_singleton_method(:from_omniauth) do |_auth|
          User.find_by(email: 'different_user@example.com')
        end
      end

      it "sets flash alert and redirects to edit user registration path" do
        get :openid_connect

        expect(flash[:alert]).to eq(
          "The current #{@identifier_scheme.description} iD has been already linked to a user with email #{different_user.email}"
        )
        expect(response).to redirect_to(edit_user_registration_path)
      end
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
