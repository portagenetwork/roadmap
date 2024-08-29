# frozen_string_literal: true

require 'rails_helper'
require 'byebug'

# RSpec.describe Users::OmniauthCallbacksController, type: :controller do
#   describe '#openid_connect' do
#     let(:auth) do
#       OmniAuth::AuthHash.new(
#         provider: 'openid_connect',
#         uid: '123545',
#         info: {
#           email: 'test@example.com'
#         }
#       )
#     end

#     before do
#       OmniAuth.config.test_mode = true
#       OmniAuth.config.mock_auth[:openid_connect] = auth
#       request.env['omniauth.auth'] = OmniAuth.config.mock_auth[:openid_connect]
#       request.env['devise.mapping'] = Devise.mappings[:user] # If using Devise
#     end

#     let(:user) { create(:user) } # Defining the user

#     context 'when the email is missing and user does not exist' do
#       before do
#         allow(User).to receive(:from_omniauth).and_return(nil)
#         allow(auth.info).to receive(:email).and_return(nil)
#         get :openid_connect
#       end

#       it 'redirects to the registration page with a flash message' do
#         expect(flash[:notice]).to eq('Something went wrong, Please try signing-up here.')
#         expect(response).to redirect_to(new_user_registration_path)
#       end
#     end

#     context 'with correct credentials' do
#       before do
#         create(:org, managed: false, is_other: true)
#         @org = create(:org, managed: true)
#         @identifier_scheme = create(:identifier_scheme,
#                                     name: 'openid_connect',
#                                     description: 'CILogon',
#                                     active: true,
#                                     identifier_prefix: 'https://www.cilogon.org/')

#         Rails.application.env_config['devise.mapping'] = Devise.mappings[:user]
#         Rails.application.env_config['omniauth.auth'] = OmniAuth.config.mock_auth[:openid_connect]
#         allow(User).to receive(:from_omniauth).and_return(user)
#         # get :openid_connect
#       end

#       it 'links account from external credentials' do
#         expect(flash[:notice]).to eq('Linked successfully')
#         expect(response).to redirect_to(root_path)
#       end
#     end
#   end
# end
