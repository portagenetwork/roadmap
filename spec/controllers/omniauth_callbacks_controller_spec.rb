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
#       OmniAuth.config.mock_auth[:openid_connect] = auth
#       request.env['omniauth.auth'] = OmniAuth.config.mock_auth[:openid_connect]
#       request.env['devise.mapping'] = Devise.mappings[:user] # If using Devise
#     end

#     let(:user) { create(:user) } # Defining the user

#     # context 'when the email is missing and user does not exist' do
#     #   before do
#     #     allow(User).to receive(:from_omniauth).and_return(nil)
#     #     allow(auth.info).to receive(:email).and_return(nil)
#     #     get :openid_connect
#     #   end

#     #   it 'redirects to the registration page with a flash message' do
#     #     expect(flash[:notice]).to eq('Something went wrong, Please try signing-up here.')
#     #     expect(response).to redirect_to(new_user_registration_path)
#     #   end
#     # end

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
#         get :openid_connect
#       end

#       it 'links account from external credentials' do
#         expect(flash[:notice]).to eq('Linked successfully')
#         expect(response).to redirect_to(root_path)
#       end
#     end

#     # Add other contexts as needed...
#   end
# end


require 'rails_helper'

RSpec.describe Users::OmniauthCallbacksController, type: :controller do
  describe '#openid_connect' do
    let(:auth) do
      OmniAuth::AuthHash.new(
        provider: 'openid_connect',
        uid: '123545',
        info: {
          email: 'test@example.com'
        }
      )
    end

    before do
      OmniAuth.config.test_mode = true
      OmniAuth.config.mock_auth[:openid_connect] = auth
      request.env['omniauth.auth'] = OmniAuth.config.mock_auth[:openid_connect]
      request.env['devise.mapping'] = Devise.mappings[:user] # If using Devise
    end

    let(:user) { create(:user) } # Defining the user

    context 'when the email is missing and user does not exist' do
      before do
        allow(User).to receive(:from_omniauth).and_return(nil)
        allow(auth.info).to receive(:email).and_return(nil)
        get :openid_connect
      end

      it 'redirects to the registration page with a flash message' do
        expect(flash[:notice]).to eq('Something went wrong, Please try signing-up here.')
        expect(response).to redirect_to(new_user_registration_path)
      end
    end

    context 'with correct credentials' do
      before do
        create(:org, managed: false, is_other: true)
        @org = create(:org, managed: true)
        @identifier_scheme = create(:identifier_scheme,
                                    name: 'openid_connect',
                                    description: 'CILogon',
                                    active: true,
                                    identifier_prefix: 'https://www.cilogon.org/')

        Rails.application.env_config['devise.mapping'] = Devise.mappings[:user]
        Rails.application.env_config['omniauth.auth'] = OmniAuth.config.mock_auth[:openid_connect]
        allow(User).to receive(:from_omniauth).and_return(user)
        # get :openid_connect
      end

      it 'links account from external credentials' do
        expect(flash[:notice]).to eq('Linked successfully')
        expect(response).to redirect_to(root_path)
      end
    end
  end
end




# # RSpec.describe 'OmniauthCallbacksController', type: :request do
# #   describe '#openid_connect' do
# #     # let(:auth) do
# #       # OmniAuth.config.mock_auth[:openid_connect] = OmniAuth::AuthHash.new(
# #       #   provider: 'openid_connect',
# #       #   uid: '123545',
# #       #   info: {
# #       #     email: 'test@example.com'
# #       #   }
# #       # )
# #       # request.env['omniauth.auth'] = OmniAuth.config.mock_auth[:openid_connect]
# #       # request.env['devise.mapping'] = Devise.mappings[:user] # if using Devise
# #       # request.env['omniauth.auth'] # Return the auth hash
# #     # end
# #     context 'when a user signs in with ORCID iD' do
# #     before do
# #       create(:org, managed: false, is_other: true)
# #       @org = create(:org, managed: true)
# #       @identifier_scheme = create(:identifier_scheme,
# #                                   name: 'openid_connect',
# #                                   description: 'CILogon',
# #                                   active: true,
# #                                   # uid: '12345',
# #                                   identifier_prefix: 'https://www.cilogon.org/')

# #       Rails.application.env_config['devise.mapping'] = Devise.mappings[:user]
# #       # Rails.application.env_config['omniauth.auth'] = OmniAuth.config.mock_auth[:openid_connect]
# #     end


# #     it 'creates account from external credentials' do
# #       # expect(response).to re/direct_to(root_path) # Adjust based on your app's redirect path
# #       # follow_redirect! # Follows the redirection to check the final response

# #       identifier = Identifier.last
# #       expect(identifier.value).to eql('https://www.cilogon.org/12345')

# #       # identifiable = identifier.identifiable
# #       expect(identifiable.email).to eql('user@organization.ca')
# #       expect(identifiable.firstname).to eql('John')
# #       expect(identifiable.surname).to eql('Doe')

# #       # Check that the logged-in name appears on the page
# #       expect(response.body).to include('John Doe')
# #     end
# #   end
    

# #     # context 'when the email is missing and user does not exist' do
# #     #   before do

# #     #     allow(User).to receive(:from_omniauth).and_return(nil)
# #     #     allow(auth.info).to receive(:email).and_return(nil)
# #     #     get :openid_connect
# #     #   end

# #     #   it 'redirects to the registration page with a flash message' do
# #     #     expect(flash[:notice]).to eq('Something went wrong, Please try signing-up here.')
# #     #     expect(response).to redirect_to(new_user_registration_path)
# #     #   end
# #     # end

# #     # context 'when current_user is nil and user is nil' do
# #     #   before do
# #     #     allow(User).to receive(:from_omniauth).and_return(nil)
# #     #     allow(User).to receive(:create_from_provider_data).and_return(create(:user))
# #     #     allow(IdentifierScheme).to receive(:find_by_name).and_return(create(:identifier_scheme))
# #     #     # get :openid_connect
# #     #   end

# #     #   it 'creates a new user and identifier, and redirects after signing in' do
# #     #     expect(User).to have_received(:create_from_provider_data).with(auth)
# #     #     expect(response).to redirect_to(root_path) # Assuming redirect after sign_in_and_redirect
# #     #   end
# #     # end

# #     # context 'when current_user is nil but user exists' do
# #     #   let(:user) { create(:user) }

# #     #   before do
# #     #     allow(User).to receive(:from_omniauth).and_return(user)
# #     #     # get :openid_connect
# #     #   end

# #     #   it 'signs in the user and redirects' do
# #     #     expect(controller.current_user).to eq(user)
# #     #     expect(response).to redirect_to(root_path) # Assuming redirect after sign_in_and_redirect
# #     #   end
# #     # end

# #     # context 'when user is nil but current_user exists' do
# #     #   let(:current_user) { create(:user) }

# #     #   before do
# #     #     allow(controller).to receive(:current_user).and_return(current_user)
# #     #     allow(User).to receive(:from_omniauth).and_return(nil)
# #     #     allow(IdentifierScheme).to receive(:find_by_name).and_return(create(:identifier_scheme))
# #     #     # get :openid_connect
# #     #   end

# #     #   it 'creates a new identifier and redirects to root with a flash notice' do
# #     #     expect(Identifier).to have_received(:create)
# #     #     expect(flash[:notice]).to eq('Linked successfully')
# #     #     expect(response).to redirect_to(root_path)
# #     #   end
# #     # end
# #   end
# # end


# require 'rails_helper'

# RSpec.describe 'OmniauthCallbacksController', type: :controller do
#   let(:org) { create(:org, managed: true) }
#   let(:identifier_scheme) do
#     create(:identifier_scheme,
#            name: 'openid_connect',
#            description: 'CILogon',
#            active: true,
#            identifier_prefix: 'https://www.cilogon.org/')
#   end

#   before do
#     create(:org, managed: false, is_other: true)
#     org
#     identifier_scheme

#     # Set up OmniAuth mock data for OpenID Connect
#     OmniAuth.config.test_mode = true
#     OmniAuth.config.mock_auth[:openid_connect] = OmniAuth::AuthHash.new(
#       provider: 'openid_connect',
#       uid: 'https://www.cilogon.org/12345',
#       info: {
#         email: 'user@organization.ca',
#         first_name: 'John',
#         last_name: 'Doe'
#       },
#       credentials: {
#         token: 'mock_token',
#         refresh_token: 'mock_refresh_token',
#         expires_at: Time.now + 1.week
#       }
#     )
#     Rails.application.env_config['devise.mapping'] = Devise.mappings[:user]
#     Rails.application.env_config['omniauth.auth'] = OmniAuth.config.mock_auth[:openid_connect]
#   end

#   after do
#     OmniAuth.config.mock_auth[:openid_connect] = nil
#     OmniAuth.config.test_mode = false
#   end

#   describe 'GET #openid_connect' do
#     context 'when email is missing and user is not found' do
#       before do
#         OmniAuth.config.mock_auth[:openid_connect] = OmniAuth::AuthHash.new(
#           provider: 'openid_connect',
#           uid: '12345',
#           info: {
#             email: nil, # Email is missing
#             first_name: 'John',
#             last_name: 'Doe'
#           },
#           credentials: {
#             token: 'mock_token',
#             refresh_token: 'mock_refresh_token',
#             expires_at: Time.now + 1.week
#           }
#         )
#         Rails.application.env_config['omniauth.auth'] = OmniAuth.config.mock_auth[:openid_connect]
#       end

#       it 'redirects to the registration path with a flash notice' do
#         # get :openid_connect

#         expect(response).to redirect_to(new_user_registration_path)
#         expect(flash[:notice]).to eq('Something went wrong, Please try signing-up here.')
#       end
#     end

#     context 'when there is no current user and no existing user is found' do
#       it 'creates a new user from the provider data and signs them in' do
#         # expect {
#         #   get :openid_connect
#         # }.to change(User, :count).by(1)

#         user = User.last
#         expect(user.email).to eq('user@organization.ca')
#         expect(user.firstname).to eq('John')
#         expect(user.surname).to eq('Doe')

#         identifier = Identifier.last
#         expect(identifier.value).to eq('https://www.cilogon.org/12345')
#         expect(identifier.identifiable).to eq(user)

#         expect(response).to redirect_to(root_path) # Adjust if the redirect path is different
#       end
#     end

#     context 'when a user is already logged in and no existing user is found with the OAuth data' do
#       let(:current_user) { create(:user, :org_admin, org: org) }

#       before do
#         sign_in current_user
#       end

#       it 'links the OAuth account to the current user and redirects with a flash notice' do
#         # expect {
#         #   get :openid_connect
#         # }.to change(Identifier, :count).by(1)

#         identifier = Identifier.last
#         expect(identifier.value).to eq('https://www.cilogon.org/12345')
#         expect(identifier.identifiable).to eq(current_user)

#         expect(response).to redirect_to(root_path)
#         expect(flash[:notice]).to eq('Linked successfully')
#       end
#     end
#   end
# end


# require 'rails_helper'

# RSpec.describe 'OmniauthCallbacksController', type: :request do
#   context 'with correct credentials' do
#     before do
#       create(:org, managed: false, is_other: true)
#       @org = create(:org, managed: true)
#       @identifier_scheme = create(:identifier_scheme,
#                                   name: 'openid_connect',
#                                   description: 'CILogon',
#                                   active: true,
#                                   identifier_prefix: 'https://www.cilogon.org/')

#       Rails.application.env_config['devise.mapping'] = Devise.mappings[:user]
#       Rails.application.env_config['omniauth.auth'] = OmniAuth.config.mock_auth[:openid_connect]
#     end

#     it 'creates account from external credentials' do

#       identifier = Identifier.last
#       expect(identifier.value).to eql('https://www.cilogon.org/12345')
#       identifiable = identifier.identifiable
#       expect(identifiable.email).to eql('user@organization.ca')
#       expect(identifiable.firstname).to eql('John')
#       expect(identifiable.surname).to eql('Doe')

#       # Check logged in name
#       expect(page).to have_content('John Doe')
#     end

#     it 'links account from external credentails' do
#       # Create existing user
#       create(:user, :org_admin, org: @org, email: 'user@organization.ca')
   
#       identifier = Identifier.last
#       expect(identifier.value).to eql('https://www.cilogon.org/12345')
#       identifiable = identifier.identifiable
#       # We will find the new user with the email specified above
#       expect(identifiable.email).to eql('user@organization.ca')

#       # XXX Check for flash notice message linked successfully
#     end

#     it 'links account from external credentials' do
#       expect(flash[:notice]).to eq('Linked successfully')
#       expect(response).to redirect_to(root_path)
#     end
#   end
# end
