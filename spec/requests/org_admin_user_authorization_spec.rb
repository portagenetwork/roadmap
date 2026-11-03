# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Organization admin user authorization', type: :request do
  let(:org) { create(:org) }
  let(:actor) { create(:user, :org_admin, org: org) }
  let(:target) { create(:user, org: org) }
  let(:department) { create(:department, org_id: target.org_id) }
  let!(:plan) { create(:plan, title: 'Confidential target research', org: target.org) }

  before do
    create(:role, :creator, user: target, plan: plan)
    target.perms << create(:perm, :modify_templates)
    sign_in actor if actor
  end

  shared_examples 'denied user management' do
    [
      [:get, '/org/admin/users/%s/admin_grant_permissions', {}],
      [:put, '/org/admin/users/%s/admin_update_permissions', { perm_ids: [] }],
      [:get, '/org_admin/users/%s/edit', {}],
      [:put, '/org_admin/users/%s', { user: { department_id: '' } }],
      [:get, '/org_admin/users/%s/user_plans', {}],
      [:get, '/paginable/users/%s/plans', {}]
    ].each do |verb, path, parameters|
      it "denies #{verb.upcase} #{path}" do
        permissions = target.perm_ids.sort
        public_send(verb, format(path, target.id), params: parameters,
                                                   headers: { 'ACCEPT' => 'application/json' })

        expect(response).to have_http_status(actor ? :forbidden : :unauthorized)
        expect(response.body).not_to include(target.email, plan.title)
        expect(target.reload.perm_ids.sort).to eq(permissions)
        expect(target.department_id).to be_nil
      end
    end
  end

  context 'when the target belongs to another organization' do
    let(:target) { create(:user) }

    include_examples 'denied user management'

    it 'rejects permission grants even when request parameters claim the caller organization' do
      put "/org/admin/users/#{target.id}/admin_update_permissions",
          params: { perm_ids: [Perm.grant_permissions.id], org_id: org.id },
          headers: { 'ACCEPT' => 'application/json' }

      expect(response).to have_http_status(:forbidden)
      expect(target.reload.perms).not_to include(Perm.grant_permissions)
    end

    it 'rejects writing a department in the target organization' do
      put "/org_admin/users/#{target.id}",
          params: { user: { department_id: department.id, org_id: org.id } },
          headers: { 'ACCEPT' => 'application/json' }

      expect(response).to have_http_status(:forbidden)
      expect(target.reload.department_id).to be_nil
    end
  end

  context 'when the caller has no admin permissions' do
    let(:actor) { create(:user, org: org) }

    include_examples 'denied user management'
  end

  context 'when the caller is not authenticated' do
    let(:actor) { nil }

    include_examples 'denied user management'
  end

  shared_examples 'authorized user management' do
    it 'renders the permission editor' do
      get "/org/admin/users/#{target.id}/admin_grant_permissions"

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body.fetch('user').fetch('id')).to eq(target.id)
    end

    it 'renders the profile and private plan listing' do
      get "/org_admin/users/#{target.id}/edit"

      expect(response).to have_http_status(:ok)
      expect(response.body).to include(target.email, plan.title)
    end

    it 'renders the user plan page' do
      get "/org_admin/users/#{target.id}/user_plans"

      expect(response).to have_http_status(:ok)
      expect(response.body).to include(plan.title)
    end

    it 'renders the plan pagination endpoint directly' do
      get "/paginable/users/#{target.id}/plans"

      expect(response).to have_http_status(:ok)
      expect(response.body).to include(plan.title)
    end

    it 'grants a permission held by the caller' do
      put "/org/admin/users/#{target.id}/admin_update_permissions",
          params: { perm_ids: [Perm.modify_templates.id, Perm.grant_permissions.id] }

      expect(response).to have_http_status(:ok)
      expect(target.reload.perms).to include(Perm.grant_permissions)
    end

    it 'revokes a permission held by the caller' do
      put "/org/admin/users/#{target.id}/admin_update_permissions", params: { perm_ids: [] }

      expect(response).to have_http_status(:ok)
      expect(target.reload.perms).not_to include(Perm.modify_templates)
    end

    it 'assigns a department from the target organization' do
      put "/org_admin/users/#{target.id}", params: { user: { department_id: department.id } }

      expect(response).to have_http_status(:ok)
      expect(target.reload.department_id).to eq(department.id)
    end

    it 'allows clearing a department' do
      target.update!(department: department)
      put "/org_admin/users/#{target.id}", params: { user: { department_id: '' } }

      expect(response).to have_http_status(:ok)
      expect(target.reload.department_id).to be_nil
    end

    it 'rejects a department outside the target organization' do
      target.update!(department: department)
      foreign_department = create(:department, org_id: create(:org).id)
      put "/org_admin/users/#{target.id}", params: { user: { department_id: foreign_department.id } }

      expect(target.reload.department_id).to eq(department.id)
    end
  end

  context 'when the caller administers the target organization' do
    include_examples 'authorized user management'

    it 'denies the super-admin profile editor for a user in the same organization' do
      get "/super_admin/users/#{target.id}/edit", headers: { 'ACCEPT' => 'application/json' }

      expect(response).to have_http_status(:forbidden)
      expect(response.body).not_to include(target.email)
    end

    it 'denies the super-admin profile update for a user in the same organization' do
      original_email = target.email
      put "/super_admin/users/#{target.id}", params: { user: { email: 'changed@example.test' } },
                                             headers: { 'ACCEPT' => 'application/json' }

      expect(response).to have_http_status(:forbidden)
      expect(target.reload.email).to eq(original_email)
    end

    it 'does not grant or revoke permissions the caller does not hold' do
      extra_permission = create(:perm, :add_organisations)
      put "/org/admin/users/#{target.id}/admin_update_permissions",
          params: { perm_ids: [extra_permission.id] }
      expect(target.reload.perms).not_to include(extra_permission)

      target.perms << extra_permission
      put "/org/admin/users/#{target.id}/admin_update_permissions", params: { perm_ids: [] }
      expect(target.reload.perms).to include(extra_permission)
    end
  end

  context 'when the caller is a super admin in another organization' do
    let(:actor) { create(:user, :super_admin) }

    include_examples 'authorized user management'

    it 'allows the super-admin profile editor across organizations' do
      get "/super_admin/users/#{target.id}/edit"

      expect(response).to have_http_status(:ok)
      expect(response.body).to include(target.email)
    end

    it 'allows super admins to change organization and clears the old department' do
      target.update!(department: department)
      new_org = create(:org)
      put "/super_admin/users/#{target.id}",
          params: { user: { org_id: { id: new_org.id, name: new_org.name }.to_json } }

      expect(response).to have_http_status(:ok)
      expect(target.reload.org).to eq(new_org)
      expect(target.department).to be_nil
    end

    it 'allows super-admin profile updates across organizations' do
      put "/super_admin/users/#{target.id}", params: { user: { email: 'changed@example.test' } }

      expect(response).to have_http_status(:ok)
      expect(target.reload.email).to eq('changed@example.test')
    end
  end

  context 'when the caller only manages templates in the target organization' do
    let(:actor) { create(:user, org: org, perms: [create(:perm, :modify_templates)]) }

    it 'can paginate user plans without permission-granting privileges' do
      get "/paginable/users/#{target.id}/plans"

      expect(response).to have_http_status(:ok)
      expect(response.body).to include(plan.title)
    end

    it 'cannot change permissions' do
      put "/org/admin/users/#{target.id}/admin_update_permissions", params: { perm_ids: [] },
                                                                    headers: { 'ACCEPT' => 'application/json' }

      expect(response).to have_http_status(:forbidden)
      expect(target.reload.perms).to include(Perm.modify_templates)
    end
  end
end
