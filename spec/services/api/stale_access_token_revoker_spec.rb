# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Api::StaleAccessTokenRevoker do
  subject(:revoker) { described_class.new }

  let(:user) { create(:user) }
  let(:application) do
    Doorkeeper::Application.create!(name: 'app', redirect_uri: 'https://example.com/cb',
                                    scopes: 'v2_read', user_id: user.id)
  end

  def create_token(created_at:, expires_in: 300, revoked_at: nil)
    Doorkeeper::AccessToken.create!(application: application, resource_owner_id: user.id,
                                    scopes: 'v2_read', expires_in: expires_in,
                                    created_at: created_at, revoked_at: revoked_at)
  end

  describe '#call' do
    it 'revokes tokens that expired more than three months ago' do
      stale = create_token(created_at: 4.months.ago)

      expect(revoker.call).to eq(1)
      expect(stale.reload.revoked_at).to be_present
    end

    it 'respects each token\'s own expires_in' do
      # created 3 months + 1 day ago but valid for 30 days => expired < 3 months ago
      recent = create_token(created_at: 3.months.ago - 1.day, expires_in: 30.days.to_i)

      expect(revoker.call).to eq(0)
      expect(recent.reload.revoked_at).to be_nil
    end

    it 'leaves recently expired and unexpired tokens alone' do
      expired_recently = create_token(created_at: 1.month.ago)
      never_expires = create_token(created_at: 1.year.ago, expires_in: nil)

      expect(revoker.call).to eq(0)
      expect(expired_recently.reload.revoked_at).to be_nil
      expect(never_expires.reload.revoked_at).to be_nil
    end

    it 'does not change tokens that are already revoked' do
      revoked_at = 5.months.ago.change(usec: 0)
      token = create_token(created_at: 6.months.ago, revoked_at: revoked_at)

      expect(revoker.call).to eq(0)
      expect(token.reload.revoked_at).to eq(revoked_at)
    end
  end
end
