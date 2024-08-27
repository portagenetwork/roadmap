require 'rails_helper'

RSpec.describe UsersController, type: :controller do
  describe '#openid_connect' do
    let(:auth) do
      OmniAuth::AuthHash.new(
        provider: 'provider_name',
        uid: '123545',
        info: {
          email: 'test@example.com'
        }
      )
    end

    before do
      request.env['omniauth.auth'] = auth
    end

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

    context 'when current_user is nil and user is nil' do
      before do
        allow(User).to receive(:from_omniauth).and_return(nil)
        allow(User).to receive(:create_from_provider_data).and_return(create(:user))
        allow(IdentifierScheme).to receive(:find_by_name).and_return(create(:identifier_scheme))
        get :openid_connect
      end

      it 'creates a new user and identifier, and redirects after signing in' do
        expect(User).to have_received(:create_from_provider_data).with(auth)
        expect(response).to redirect_to(root_path) # Assuming redirect after sign_in_and_redirect
      end
    end

    context 'when current_user is nil but user exists' do
      let(:user) { create(:user) }

      before do
        allow(User).to receive(:from_omniauth).and_return(user)
        get :openid_connect
      end

      it 'signs in the user and redirects' do
        expect(controller.current_user).to eq(user)
        expect(response).to redirect_to(root_path) # Assuming redirect after sign_in_and_redirect
      end
    end

    context 'when user is nil but current_user exists' do
      let(:current_user) { create(:user) }

      before do
        allow(controller).to receive(:current_user).and_return(current_user)
        allow(User).to receive(:from_omniauth).and_return(nil)
        allow(IdentifierScheme).to receive(:find_by_name).and_return(create(:identifier_scheme))
        get :openid_connect
      end

      it 'creates a new identifier and redirects to root with a flash notice' do
        expect(Identifier).to have_received(:create)
        expect(flash[:notice]).to eq('Linked successfully')
        expect(response).to redirect_to(root_path)
      end
    end
  end
end
