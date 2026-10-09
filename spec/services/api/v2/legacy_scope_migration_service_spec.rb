# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Api::V2::LegacyScopeMigrationService do
  subject(:service) { described_class.new }

  let(:user) { create(:user) }

  def create_application(scopes)
    # Legacy scopes are no longer configured, so bypass validations to set them
    app = Doorkeeper::Application.create!(name: SecureRandom.hex(4), redirect_uri: 'https://example.com/cb',
                                          scopes: 'v2_read', user_id: user.id)
    app.update_column(:scopes, scopes)
    app
  end

  def create_token(application, scopes, revoked_at: nil)
    token = Doorkeeper::AccessToken.create!(application: application, resource_owner_id: user.id,
                                            scopes: 'v2_read', expires_in: 300, revoked_at: revoked_at)
    token.update_column(:scopes, scopes)
    token
  end

  describe '#call' do
    let(:read_app) { create_application('read') }
    let(:write_app) { create_application('write') }
    let(:current_app) { create_application('v2_read') }

    it 'migrates application scopes' do
      read_app
      write_app
      current_app

      expect(service.call[:applications]).to eq(2)
      expect(read_app.reload.scopes.to_s).to eq('v2_read')
      expect(write_app.reload.scopes.to_s).to eq('v2_read v2_write')
      expect(current_app.reload.scopes.to_s).to eq('v2_read')
    end

    it 'migrates unrevoked access tokens and ignores revoked ones' do
      live = create_token(write_app, 'write')
      revoked = create_token(read_app, 'read', revoked_at: Time.current)

      expect(service.call[:access_tokens]).to eq(1)
      expect(live.reload.scopes.to_s).to eq('v2_read v2_write')
      expect(revoked.reload.scopes.to_s).to eq('read')
    end

    it 'preserves unrelated scopes and is idempotent' do
      app = create_application('read admin')

      service.call
      expect(app.reload.scopes.to_s).to eq('v2_read admin')
      expect(service.call).to eq(applications: 0, access_tokens: 0)
    end
  end
end
