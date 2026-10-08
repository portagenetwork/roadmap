# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Doorkeeper applications', type: :request do
  let!(:manage_oauth_apps_perm) { create(:perm, :manage_oauth_apps) }
  let(:user) { create(:user) }

  before do
    user.perms << manage_oauth_apps_perm
    sign_in(user)
  end

  describe 'GET /oauth/applications/new' do
    it 'renders v2 scope radio buttons with read access preselected' do
      get new_oauth_application_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include('type="radio"')
      expect(response.body).to match(/value="v2_read"[^>]*checked/)
      expect(response.body).to include('value="v2_read v2_write"')
    end
  end

  describe 'POST /oauth/applications' do
    let(:base_params) do
      { name: 'Test app', redirect_uri: 'https://example.com/callback' }
    end

    it 'saves a v2 read-only application' do
      post oauth_applications_path,
           params: { doorkeeper_application: base_params.merge(scopes: 'v2_read') }

      expect(Doorkeeper::Application.last.scopes.to_s).to eq('v2_read')
    end

    it 'saves a v2 read/write application' do
      post oauth_applications_path,
           params: { doorkeeper_application: base_params.merge(scopes: 'v2_read v2_write') }

      expect(Doorkeeper::Application.last.scopes.to_s).to eq('v2_read v2_write')
    end

    it 'saves a Common MaDMP read-only application' do
      post oauth_applications_path,
           params: { doorkeeper_application: base_params.merge(scopes: 'common_madmp_read') }

      expect(Doorkeeper::Application.last.scopes.to_s).to eq('common_madmp_read')
    end

    it 'saves a Common MaDMP read/write application' do
      post oauth_applications_path,
           params: { doorkeeper_application: base_params.merge(scopes: 'common_madmp_read common_madmp_write') }

      expect(Doorkeeper::Application.last.scopes.to_s).to eq('common_madmp_read common_madmp_write')
    end

    it 'rejects a scope that is not configured' do
      post oauth_applications_path,
           params: { doorkeeper_application: base_params.merge(scopes: 'v2_read admin') }

      expect(response).not_to be_redirect
      expect(Doorkeeper::Application.count).to eq(0)
    end
  end

  describe 'without the manage perm' do
    before do
      user.perms.delete(manage_oauth_apps_perm)
    end

    it 'redirects away from the form' do
      get new_oauth_application_path

      expect(response).to redirect_to(root_path)
    end
  end
end
