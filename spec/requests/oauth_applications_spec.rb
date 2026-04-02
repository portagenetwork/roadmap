# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'OauthApplications', type: :request do
  let!(:manage_oauth_apps_perm) { create(:perm, :manage_oauth_apps) }
  let(:authorized_user) { create(:user) }
  let(:unauthorized_user) { create(:user) }
  let(:super_admin) { create(:user, :super_admin) }

  def sign_in_with_manage_oauth_apps(user)
    user.perms << manage_oauth_apps_perm
    sign_in(user)
  end

  before do
    sign_in_with_manage_oauth_apps(authorized_user)
  end

  shared_examples 'denies access without manage_oauth_apps permission' do
    before do
      sign_in(unauthorized_user)
      get request_path
    end

    it 'redirects to root with an authorization alert' do
      expect(response).to redirect_to(root_path)
      follow_redirect!
      expect(flash[:alert]).to include('not authorized')
    end
  end

  shared_examples 'owner-only oauth application update' do
    it 'allows updating own application' do
      owned_application = create(:oauth_application, user_id: current_user.id, name: 'Owned App')

      patch oauth_application_path(owned_application), params: { doorkeeper_application: { name: 'Updated Name' } }

      expect(response).to redirect_to(oauth_application_path(owned_application))
      expect(owned_application.reload.name).to eq('Updated Name')
    end

    it 'denies updating another user application' do
      other_user_application = create(:oauth_application, user_id: create(:user).id, name: 'Other User App')

      patch oauth_application_path(other_user_application),
            params: { doorkeeper_application: { name: 'Updated Name' } }

      expect(response).to redirect_to(root_path)
      expect(other_user_application.reload.name).to eq('Other User App')
      follow_redirect!
      expect(flash[:alert]).to include('not authorized')
    end
  end

  shared_examples 'owner-only oauth application destroy' do
    it 'allows destroying own application' do
      owned_application = create(:oauth_application, user_id: current_user.id)

      expect do
        delete oauth_application_path(owned_application)
      end.to change(Doorkeeper::Application, :count).by(-1)

      expect(response).to redirect_to(oauth_applications_path)
    end

    it 'denies destroying another user application' do
      other_user_application = create(:oauth_application, user_id: create(:user).id)

      expect do
        delete oauth_application_path(other_user_application)
      end.not_to change(Doorkeeper::Application, :count)

      expect(response).to redirect_to(root_path)
      follow_redirect!
      expect(flash[:alert]).to include('not authorized')
    end
  end

  describe 'GET /oauth/applications' do
    context 'when signed in without manage_oauth_apps permission' do
      let(:request_path) { oauth_applications_path }

      include_examples 'denies access without manage_oauth_apps permission'
    end

    context 'when signed in as a super user (with manage_oauth_apps permission)' do
      let!(:application_one) { create(:oauth_application, user_id: create(:user).id, name: 'OAuth App 1') }
      let!(:application_two) { create(:oauth_application, user_id: create(:user).id, name: 'OAuth App 2') }

      before do
        sign_in(super_admin)
      end

      it 'shows all oauth applications' do
        get oauth_applications_path

        expect(response).to have_http_status(:ok)
        html = Nokogiri::HTML(response.body)

        expect(html.at_css("#application_#{application_one.id}")).to_not be_nil
        expect(html.at_css("#application_#{application_two.id}")).to_not be_nil
      end
    end

    context 'when signed in as non-super user with manage_oauth_apps permission' do
      let(:other_user) { create(:user) }
      let!(:owned_application) { create(:oauth_application, user_id: authorized_user.id, name: 'Owned App') }
      let!(:other_user_application) { create(:oauth_application, user_id: other_user.id, name: 'Other User App') }

      before do
        sign_in(authorized_user)
      end

      it 'shows only oauth applications for the current user' do
        get oauth_applications_path

        expect(response).to have_http_status(:ok)
        html = Nokogiri::HTML(response.body)

        expect(html.at_css("#application_#{owned_application.id}")).to_not be_nil
        expect(html.at_css("#application_#{other_user_application.id}")).to be_nil
      end
    end
  end

  describe 'GET /oauth/applications/new' do
    context 'when signed in with manage_oauth_apps permission' do
      before do
        sign_in(authorized_user)
      end

      it 'renders the expected form fields and default scopes' do
        get new_oauth_application_path

        expect(response).to have_http_status(:ok)
        html = Nokogiri::HTML(response.body)

        name_input = html.at_css('#doorkeeper_application_name')
        expect(name_input['name']).to eq('doorkeeper_application[name]')
        expect(name_input['required']).to eq('required')

        scopes_input = html.at_css('#doorkeeper_application_scopes')
        expect(scopes_input['name']).to eq('doorkeeper_application[scopes]')
        expect(scopes_input['value']).to eq(Doorkeeper.config.default_scopes.to_s)
        expect(scopes_input['readonly']).to eq('readonly')

        redirect_uri_input = html.at_css('#doorkeeper_application_redirect_uri')
        expect(redirect_uri_input['name']).to eq('doorkeeper_application[redirect_uri]')

        submit_button = html.at_css("input[type='submit'].btn.btn-primary")
        expect(submit_button['value']).to eq('Submit')

        cancel_link = html.at_css("a.btn.btn-secondary[href='#{oauth_applications_path}']")
        expect(cancel_link.text).to eq('Cancel')
      end
    end

    context 'when signed in without manage_oauth_apps permission' do
      let(:request_path) { new_oauth_application_path }

      include_examples 'denies access without manage_oauth_apps permission'
    end
  end

  describe 'GET /oauth/applications/:id' do
    let(:application_owner) { create(:user) }
    let(:application) { create(:oauth_application, user_id: application_owner.id) }

    context 'when signed in as super user with manage_oauth_apps permission' do
      before do
        sign_in(super_admin)
      end

      it 'allows access' do
        get oauth_application_path(application)

        expect(response).to have_http_status(:ok)
      end
    end

    context 'when signed in as a normal user without manage_oauth_apps permission' do
      let(:request_path) { oauth_application_path(application) }

      include_examples 'denies access without manage_oauth_apps permission'
    end

    context 'when signed in as a non-super user with manage_oauth_apps permission' do
      let(:other_authorized_user) { create(:user) }

      before do
        sign_in_with_manage_oauth_apps(other_authorized_user)
        sign_in(authorized_user)
      end

      it 'allows access when the application belongs to the current user' do
        owned_application = create(:oauth_application, user_id: authorized_user.id)

        get oauth_application_path(owned_application)

        expect(response).to have_http_status(:ok)
      end

      it 'denies access when the application belongs to another user' do
        other_user_application = create(:oauth_application, user_id: other_authorized_user.id)

        get oauth_application_path(other_user_application)

        expect(response).to redirect_to(root_path)
        follow_redirect!
        expect(flash[:alert]).to include('not authorized')
      end
    end
  end

  describe 'PATCH /oauth/applications/:id' do
    context 'when signed in as super user' do
      let(:current_user) { super_admin }

      before do
        sign_in(super_admin)
      end

      include_examples 'owner-only oauth application update'
    end

    context 'when signed in as a non-super user with manage_oauth_apps permission' do
      let(:current_user) { authorized_user }

      before do
        sign_in(authorized_user)
      end

      include_examples 'owner-only oauth application update'
    end
  end

  describe 'DELETE /oauth/applications/:id' do
    context 'when signed in as super user' do
      let(:current_user) { super_admin }

      before do
        sign_in(super_admin)
      end

      include_examples 'owner-only oauth application destroy'
    end

    context 'when signed in as a non-super user with manage_oauth_apps permission' do
      let(:current_user) { authorized_user }

      before do
        sign_in(authorized_user)
      end

      include_examples 'owner-only oauth application destroy'
    end
  end
end
