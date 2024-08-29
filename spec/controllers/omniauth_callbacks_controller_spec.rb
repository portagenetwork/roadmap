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


# require 'rails_helper'

# RSpec.describe Users::OmniauthCallbacksController, type: :controller do
#   before do
#     # Setting up the mock Omniauth data for OpenID Connect
#     OmniAuth.config.test_mode = true
#     @request.env["devise.mapping"] = Devise.mappings[:user] # Map to devise user

#     # Example valid mock_auth hash
#     OmniAuth.config.mock_auth[:openid_connect] = OmniAuth::AuthHash.new({
#       provider: 'openid_connect',
#       uid: '12345',
#       info: {
#         email: 'test@example.com',
#         name: 'Test User'
#       }
#     })

#     # Omniauth authentication hash setup in request env
#     @request.env["omniauth.auth"] = OmniAuth.config.mock_auth[:openid_connect]
#   end

#   describe 'GET #openid_connect' do
#     let(:auth) { request.env['omniauth.auth'] }
#     let(:identifier_scheme) { create(:identifier_scheme, name: auth.provider) }

#     context 'when the email is missing and the user does not exist' do
#       before do
#         # Adjust the mock_auth to simulate missing email
#         OmniAuth.config.mock_auth[:openid_connect].info.email = nil
#         @request.env["omniauth.auth"] = OmniAuth.config.mock_auth[:openid_connect]
#         allow(User).to receive(:from_omniauth).and_return(nil)
#       end

#       it 'redirects to the registration page with a flash message' do
#         get :openid_connect

#         expect(response).to redirect_to(new_user_registration_path)
#         expect(flash[:notice]).to eq('Something went wrong, Please try signing-up here.')
#       end
#     end













# # require 'rails_helper'

# # RSpec.describe Users::OmniauthCallbacksController, type: :controller do
# #   describe '#openid_connect' do
# #     let(:auth) do
# #       OmniAuth::AuthHash.new(
# #         provider: 'openid_connect',
# #         uid: '123545',
# #         info: {
# #           email: 'test@example.com',
# #           first_name: 'Test',
# #           last_name: 'User'
# #         }
# #       )
# #     end

# #     before do
# #       OmniAuth.config.test_mode = true
# #       OmniAuth.config.mock_auth[:openid_connect] = auth
# #       request.env['omniauth.auth'] = OmniAuth.config.mock_auth[:openid_connect]
# #       request.env['devise.mapping'] = Devise.mappings[:user] # If using Devise
# #     end

# #     let(:user) { create(:user) } # Defining the user


# #     describe 'GET #openid_connect' do
# #       context 'when user exists' do
# #         let!(:user) { create(:user, email: 'test@example.com') }
  
# #         it 'signs in the user and redirects to root path' do
# #           get :openid_connect
  
# #           expect(subject.current_user).to eq(user)
# #           expect(response).to redirect_to(root_path)
# #           expect(flash[:notice]).to eq('Successfully authenticated from OpenID Connect account.')
# #         end
# #       end
# #       context 'when user does not exist' do
# #         it 'redirects to registration page with a flash message' do
# #           get :openid_connect
  
# #           expect(response).to redirect_to(new_user_registration_url)
# #           expect(flash[:alert]).to eq('Email has already been taken')
# #         end
# #       end
  
# #       context 'when authentication fails' do
# #         before do
# #           OmniAuth.config.mock_auth[:openid_connect] = :invalid_credentials
# #         end

# #         it 'redirects to the new session path' do
# #           get :openid_connect
  
# #           expect(response).to redirect_to(new_user_session_path)
# #           expect(flash[:alert]).to eq('Could not authenticate you from OpenID Connect because "Invalid credentials".')
# #         end
# #       end  

# #       context 'when the email is missing and user does not exist' do
# #         before do
# #           byebug
# #           allow(User).to receive(:from_omniauth).and_return(nil)
# #           allow(auth.info).to receive(:email).and_return(nil)
# #           # get :openid_connect
# #         end

# #         it 'redirects to the registration page with a flash message' do
# #           expect(flash[:notice]).to eq('Something went wrong, Please try signing-up here.')
# #           expect(response).to redirect_to(new_user_registration_path)
# #         end
# #       end

# #     context 'with correct credentials' do
# #       before do
# #         create(:org, managed: false, is_other: true)
# #         @org = create(:org, managed: true)
# #         @identifier_scheme = create(:identifier_scheme,
# #                                     name: 'openid_connect',
# #                                     description: 'CILogon',
# #                                     active: true,
# #                                     identifier_prefix: 'https://www.cilogon.org/')

# #         Rails.application.env_config['devise.mapping'] = Devise.mappings[:user]
# #         Rails.application.env_config['omniauth.auth'] = OmniAuth.config.mock_auth[:openid_connect]
# #         allow(User).to receive(:from_omniauth).and_return(user)
# #         # get :openid_connect
# #       end

# #       it 'links account from external credentials' do
# #         expect(flash[:notice]).to eq('Linked successfully')
# #         expect(response).to redirect_to(root_path)
# #       end
# #     end
# #   end
# # end
# # end




# # #         expect(response).to redirect_to(new_user_registration_path)
# # #         expect(flash[:notice]).to eq('Something went wrong, Please try signing-up here.')
# # #       end
# # #     end

# # #     context 'when there is no current user and no existing user is found' do
# # #       it 'creates a new user from the provider data and signs them in' do
# # #         # expect {
# # #         #   get :openid_connect
# # #         # }.to change(User, :count).by(1)

# # #         user = User.last
# # #         expect(user.email).to eq('user@organization.ca')
# # #         expect(user.firstname).to eq('John')
# # #         expect(user.surname).to eq('Doe')

# # #         identifier = Identifier.last
# # #         expect(identifier.value).to eq('https://www.cilogon.org/12345')
# # #         expect(identifier.identifiable).to eq(user)

# # #         expect(response).to redirect_to(root_path) # Adjust if the redirect path is different
# # #       end
# # #     end

# # #     context 'when a user is already logged in and no existing user is found with the OAuth data' do
# # #       let(:current_user) { create(:user, :org_admin, org: org) }

# # #       before do
# # #         sign_in current_user
# # #       end

# # #       it 'links the OAuth account to the current user and redirects with a flash notice' do
# # #         # expect {
# # #         #   get :openid_connect
# # #         # }.to change(Identifier, :count).by(1)

# # #         identifier = Identifier.last
# # #         expect(identifier.value).to eq('https://www.cilogon.org/12345')
# # #         expect(identifier.identifiable).to eq(current_user)

# # #         expect(response).to redirect_to(root_path)
# # #         expect(flash[:notice]).to eq('Linked successfully')
# # #       end
# # #     end
# # #   end
# # # end
