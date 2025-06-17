# frozen_string_literal: true

require 'rails_helper'

FLASH_MESSAGES = {
  notice: {
    linked: 'Linked successfully',
    signed_in: 'Signed in successfully.'
  },
  alert: {
    missing_profile: 'Some information is missing from your profile. ' \
                     '<a href="/users/edit">Click here to complete your profile</a>.',
    missing_email_sign_in: 'Unable to sign in with the selected identity provider. ' \
                           'Consider using an alternative sign in method, like social sign on. ' \
                           'You can verify your email is being provided here ' \
                           '<<a href="https://cilogon.org/testidp/">https://cilogon.org/testidp/</a>> ' \
                           'and contact us at the help desk for further assistance. Help desk email: ' \
                           '<a href="mailto:dmp-assistant@tech.alliancecan.ca">dmp-assistant@tech.alliancecan.ca</a>'
  }
}.freeze
FLASH_MESSAGES[:alert][:missing_email_link] = FLASH_MESSAGES[:alert][:missing_email_sign_in].sub('sign in', 'link')

RSpec.describe Users::OmniauthCallbacksController, type: :controller do
  before do
    # Setup Devise mapping
    @request.env['devise.mapping'] = Devise.mappings[:user]
    create(:org, managed: false, is_other: true)
    @identifier_scheme = create(:identifier_scheme, :openid_connect)
    @request.env['omniauth.auth'] = OmniAuth.config.mock_auth[:openid_connect].dup
  end

  describe 'POST #openid_connect' do
    context 'A user attempts to sign in using valid external credentials.' do
      context 'The credentials are linked to an existing account' do
        let!(:user) { create(:user) }

        before do
          create_user_identifier_from_auth(user)
        end
        it 'Signs the user in successfully' do
          expect(User.count).to eq(1)
          expect(Identifier.count).to eq(1)
          expectations_for_openid_connect_sign_in
        end
      end

      context 'The credentials are not yet linked to an existing account' do
        context 'Generic case.' do
          it 'Signs in the user successfully' do
            expect(User.count).to eq(0)
            expect(Identifier.count).to eq(0)
            expectations_for_openid_connect_sign_in
            user = User.first
            # The attribute values correspond with User.find_or_create_from_provider_data(provider_data)
            expect(user.email).to eq(@request.env['omniauth.auth'].info.email)
            expect(user.firstname).to eq(@request.env['omniauth.auth'].info.first_name)
            expect(user.surname).to eq(@request.env['omniauth.auth'].info.last_name)
            expect(user.org).to eq(Org.find_by(is_other: true))
            expect(user.accept_terms).to eq(true)
          end
        end

        context 'The auth email matches an existing user email' do
          # Set user email to match auth email
          let!(:user) { create(:user, email: @request.env['omniauth.auth'].info.email) }
          it 'Signs in the user successfully' do
            expect(User.count).to eq(1)
            expect(Identifier.count).to eq(0)
            expectations_for_openid_connect_sign_in
            # The newly-created Identifier belongs to the existing User with the same email
            expect(User.first.identifiers.count).to eq(1)
          end
        end

        context '`first_name` and `last_name` are absent from the auth data.' do
          before do
            # Set the auth data's first_name and last_name to nil
            @request.env['omniauth.auth'].info.first_name = nil
            @request.env['omniauth.auth'].info.last_name = nil
          end
          it 'Signs in the user and renders a flash alert to update their profile' do
            expect(User.count).to eq(0)
            expect(Identifier.count).to eq(0)
            expectations_for_openid_connect_sign_in_with_generic_name
          end
        end
      end
    end

    context 'A user is signed in and attempts to link their external credentials.' do
      context 'Generic case.' do
        let!(:user) { create(:user) }

        before do
          sign_in user
        end

        it 'Successfully links their credentials.' do
          expect do
            post :openid_connect
            user.reload
          end.to change(user.identifiers, :count).by(1)
          expect(User.count).to eq(1)
          expect(Identifier.count).to eq(1)
          expect(flash[:notice]).to eq(FLASH_MESSAGES[:notice][:linked])
          expect(response).to redirect_to(edit_user_registration_path)
        end
      end

      context 'The external credentials are already linked to another user' do
        let!(:user) { create(:user) }
        let!(:other_user) { create(:user) }

        before do
          # Link the mocked auth data to `other_user`
          create_user_identifier_from_auth(other_user)
          sign_in user
        end

        it 'Does not link their credentials' do
          post :openid_connect

          expect(flash[:alert]).to eq(
            "The current #{@identifier_scheme.description} iD has been already linked " \
            "to a user with email #{other_user.email}"
          )
          expect(response).to redirect_to(edit_user_registration_path)
          expect(User.count).to eq(2)
          expect(Identifier.count).to eq(1)
        end
      end
    end

    context 'The credentials are not yet linked to an existing account and the email is nil.' do
      let!(:user) { create(:user) }
      before do
        # Simulate missing email
        @request.env['omniauth.auth'].info.email = nil
      end
      context 'The user is attempting to sign in with the external credentials.' do
        it 'Does not link the credentials, renders a flash alert, and redirects the user to the root path.' do
          post :openid_connect
          expect(response).to redirect_to(root_path)
          expect(flash[:alert]).to eq(FLASH_MESSAGES[:alert][:missing_email_sign_in])
          expect(User.count).to eq(1)
          expect(Identifier.count).to eq(0)
        end
      end

      context 'The user is signed in and attempting to link the external credentials.' do
        it 'Does not link the credentials, renders a flash alert, and redirects the user to the Edit Profile page.' do
          sign_in user
          post :openid_connect
          expect(response).to redirect_to(edit_user_registration_path)
          expect(flash[:alert]).to eq(FLASH_MESSAGES[:alert][:missing_email_link])
          expect(User.count).to eq(1)
          expect(Identifier.count).to eq(0)
        end
      end
    end

    private

    def create_user_identifier_from_auth(user)
      Identifier.create(identifier_scheme: @identifier_scheme,
                        value: request.env['omniauth.auth'].uid,
                        attrs: request.env['omniauth.auth'],
                        identifiable: user)
    end

    # rubocop:disable Metrics/AbcSize
    def expectations_for_openid_connect_sign_in
      post :openid_connect
      expect(response).to redirect_to(root_path)
      expect(flash[:notice]).to eq(FLASH_MESSAGES[:notice][:signed_in])
      expect(User.count).to eq(1)
      expect(Identifier.count).to eq(1)
    end
    # rubocop:enable Metrics/AbcSize

    # rubocop:disable Metrics/AbcSize
    def expectations_for_openid_connect_sign_in_with_generic_name
      post :openid_connect
      expect(response).to redirect_to(root_path)
      expect(flash[:alert]).to eq(FLASH_MESSAGES[:alert][:missing_profile])
      expect(User.count).to eq(1)
      expect(Identifier.count).to eq(1)
      user = User.first
      expect(user.firstname).to eq(User::GENERIC_USER_NAME_VALUES[:firstname])
      expect(user.surname).to eq(User::GENERIC_USER_NAME_VALUES[:surname])
    end
    # rubocop:enable Metrics/AbcSize
  end
end
