require 'rails_helper'
# require 'rspec/rails'


    RSpec.describe UsersController, type: :controller do
      describe '#openid_connect' do
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
        end
      
        it 'links account from external credentails' do
          # Create existing user
          create(:user, :org_admin, org: @org, email: 'user@organization.ca')
          visit root_path
          click_link 'Sign in with ORCID iD'
          identifier = Identifier.last
          expect(identifier.value).to eql('https://www.cilogon.org/12345')
          identifiable = identifier.identifiable
          # We will find the new user with the email specified above
          expect(identifiable.email).to eql('user@organization.ca')
    
          # XXX Check for flash notice message linked successfully
          expect(flash[:notice]).to eq('linked successfully')
        end


      end
    end

# # RSpec.describe UsersController, type: :controller do
# #   describe '#openid_connect' do
# #     before do
# #       OmniAuth.config.mock_auth[:openid_connect] = OmniAuth::AuthHash.new(
# #         provider: 'openid_connect',
# #         uid: '123545',
# #         info: {
# #           email: 'test@example.com'
# #         }
# #       )
# #       request.env['omniauth.auth'] = OmniAuth.config.mock_auth[:openid_connect]
# #       request.env['devise.mapping'] = Devise.mappings[:user] # if using Devise

# #     end

# #     let(:user) { create(:user) } # Defining the user

# #     context 'when a user does exist' do
# #       before do
# #         allow(User).to receive(:from_omniauth).and_return(user)
# #       end

# #       it 'signs in the user and redirects' do
# #         expect(controller.current_user).not_to eq(user)
# #       end
# #     end

# #     # Other contexts...
# #   end
# # end


# RSpec.describe UsersController, type: :controller do
#   describe '#openid_connect' do
#     let(:user) { create(:user) } # Defining the user
#     let(:auth) do
#       OmniAuth.config.mock_auth[:openid_connect] = OmniAuth::AuthHash.new(
#         provider: 'openid_connect',
#         uid: '123545',
#         info: {
#           email: 'test@example.com'
#         }
#       )
#       request.env['omniauth.auth'] = OmniAuth.config.mock_auth[:openid_connect]
#       request.env['devise.mapping'] = Devise.mappings[:user] # if using Devise
#       request.env['omniauth.auth'] # Return the auth hash
#     end


#     context 'when a user does exist' do
#       before do
#         allow(User).to receive(:from_omniauth).and_return(nil)
#       end

#       it 'signs in the user and redirects' do
#         expect(controller.current_user).not_to eq(user)
#       end
#     end
    

#     context 'when the email is missing and user does not exist' do
#       before do

#         allow(User).to receive(:from_omniauth).and_return(nil)
#         allow(auth.info).to receive(:email).and_return(nil)
#         # get :openid_connect # we need to set the rspec Router for this
#       end

#       it 'redirects to the registration page with a flash message' do
#         expect(flash[:notice]).to eq('Something went wrong, Please try signing-up here.')
#         expect(response).to redirect_to(new_user_registration_path)
#       end
#     end

#     context 'when current_user is nil and user is nil' do
#       before do
#         allow(User).to receive(:from_omniauth).and_return(nil)
#         allow(User).to receive(:create_from_provider_data).and_return(create(:user))
#         allow(IdentifierScheme).to receive(:find_by_name).and_return(create(:identifier_scheme))
#         # get :openid_connect
#       end

#       it 'creates a new user and identifier, and redirects after signing in' do
#         expect(User).to have_received(:create_from_provider_data).with(auth)
#         expect(response).to redirect_to(root_path) # Assuming redirect after sign_in_and_redirect
#       end
#     end

#     context 'when current_user is nil but user exists' do
#       let(:user) { create(:user) }

#       before do
#         allow(User).to receive(:from_omniauth).and_return(user)
#         # get :openid_connect
#       end

#       it 'signs in the user and redirects' do
#         expect(controller.current_user).to eq(user)
#         expect(response).to redirect_to(root_path) # Assuming redirect after sign_in_and_redirect
#       end
#     end

#     context 'when user is nil but current_user exists' do
#       let(:current_user) { create(:user) }

#       before do
#         allow(controller).to receive(:current_user).and_return(current_user)
#         allow(User).to receive(:from_omniauth).and_return(nil)
#         allow(IdentifierScheme).to receive(:find_by_name).and_return(create(:identifier_scheme))
#         # get :openid_connect
#       end

#       it 'creates a new identifier and redirects to root with a flash notice' do
#         expect(Identifier).to have_received(:create)
#         expect(flash[:notice]).to eq('Linked successfully')
#         expect(response).to redirect_to(root_path)
#       end
#     end
#   end
# end



require 'rails_helper'

RSpec.describe UsersController, type: :controller do
  describe '#create' do
    let(:user_params) { attributes_for(:user) }

    context 'when user is successfully created' do
      before do
        allow(User).to receive(:new).and_return(build_stubbed(:user))
        allow_any_instance_of(User).to receive(:save).and_return(true)
        post :create, params: { user: user_params }
      end

      it 'redirects to the user page' do
        expect(response).to redirect_to(user_path(assigns(:user)))
      end

      it 'sets a flash notice' do
        expect(flash[:notice]).to eq('User was successfully created.')
      end
    end

    context 'when user creation fails' do
      before do
        allow(User).to receive(:new).and_return(build_stubbed(:user))
        allow_any_instance_of(User).to receive(:save).and_return(false)
        post :create, params: { user: user_params }
      end

      it 'renders the new template' do
        expect(response).to render_template(:new)
      end
    end
  end
end
