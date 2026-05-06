# frozen_string_literal: true

require 'rails_helper'

RSpec.describe OauthApplicationsController, type: :controller do
  let!(:manage_oauth_apps_perm) { create(:perm, :manage_oauth_apps) }
  let(:user) { create(:user) }

  before do
    user.perms << manage_oauth_apps_perm
    sign_in(user)
  end

  describe '#application_params' do
    it 'merges user_id into the parent params' do
      Doorkeeper::ApplicationsController.any_instance
                                        # Ensure parent controller has application_params implemented
                                        .expects(:application_params)
                                        .returns({ name: 'Test OAuth App' })

      # Call the (private) method on our own controller
      result = controller.send(:application_params)

      expect(result[:name]).to eq('Test OAuth App')
      # Ensure our controller adds user.id
      expect(result[:user_id]).to eq(user.id)
    end
  end
end
