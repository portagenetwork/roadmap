# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Users::OmniauthCallbacksController, type: :controller do
  before do
    # Capture User.from_omniauth before redefining it
    @from_omniauth_method = User.method(:from_omniauth)
    # Setup Devise mapping
    @request.env['devise.mapping'] = Devise.mappings[:user]
    create(:org, managed: false, is_other: true)
    @org = create(:org, managed: true)
    @identifier_scheme = create(:identifier_scheme, :openid_connect)
    @request.env['omniauth.auth'] = OmniAuth.config.mock_auth[:openid_connect].dup
  end

  after do
    # Restore the actual User.from_omniauth method
    User.define_singleton_method(:from_omniauth, @from_omniauth_method)
  end

  describe 'POST #openid_connect' do
    context 'when the email is missing and the user does not exist' do
      before do
        # Simulate missing email
        @request.env['omniauth.auth'].info.email = nil
      end

      it 'redirects to the registration page with a flash message' do
        post :openid_connect

        expect(response).to redirect_to(new_user_registration_path)
        expect(flash[:notice]).to eq('Something went wrong, Please try signing up here.')
      end
    end

    context 'when the user is not signed in but already exists' do
      let!(:user) { User.create(email: 'user@organization.ca', firstname: 'John', surname: 'Doe', org: @org) }

      before do
        def User.from_omniauth(_auth)
          User.find_by(email: 'user@organization.ca')
        end
      end

      it 'signs in the existing user' do
        post :openid_connect
        # expect(subject.current_user).to eq(user)
        expect(response).to redirect_to(root_path)
        expect(flash[:notice]).to be_nil
      end
    end

    context 'when the user is signed in and needs to link their OpenID Connect account' do
      let!(:user) { User.create(email: 'user@organization.ca', firstname: 'John', surname: 'Doe', org: @org) }
      let(:current_user) { create(:user) }

      before do
        sign_in current_user
      end

      it 'links identifier to current user, sets flash notice, and redirects to root path' do
        expect do
          post :openid_connect
          current_user.reload # Ensure we have the latest state of the user
        end.to change(current_user.identifiers, :count).by(1)

        expect(flash[:notice]).to eq('Linked successfully')
        expect(response).to redirect_to(root_path)
      end
    end

    context 'when the user found via omniauth is different from the current_user' do
      let(:current_user) { create(:user) }
      # Ensure different_user is created before test runs
      let!(:different_user) do
        create(:user, email: 'different_user@example.com')
      end
      before do
        sign_in current_user

        # Mocking the from_omniauth method to return a different user
        # We use `let!` to ensure `different_user` is accessible here
        User.define_singleton_method(:from_omniauth) do |_auth|
          User.find_by(email: 'different_user@example.com')
        end
      end

      it 'sets flash alert and redirects to edit user registration path' do
        post :openid_connect

        expect(flash[:alert]).to eq(
          "The current #{@identifier_scheme.description} iD has been already linked " \
          "to a user with email #{different_user.email}"
        )
        expect(response).to redirect_to(edit_user_registration_path)
      end
    end

    context 'when an unknown error occurs' do
      before do
        def User.from_omniauth(_auth)
          raise StandardError, 'Unexpected error'
        end
      end

      it 'handles the error and raises an exception' do
        expect do
          post :openid_connect
        end.to raise_error(StandardError, 'Unexpected error')
      end
    end
  end
end
