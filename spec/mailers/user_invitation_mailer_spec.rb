# frozen_string_literal: true

# spec/mailers/user_invitation_mailer_spec.rb
require 'rails_helper'

RSpec.describe 'User invitation email', type: :mailer do
  describe 'Invitation Email to User Not in DB' do
    let(:inviter) { create(:user) }
    let(:invitee) { User.new(email: 'newuser@example.com') }

    before do
      ActionMailer::Base.deliveries.clear
    end

    it 'sends an invitation email with a bilingual subject' do
      # Simulate Devise invitation context
      invitee.invitation_token = Devise.friendly_token
      invitee.invited_by = inviter
      invitee.invited_by_type = 'User'

      # Trigger mailer directly
      # deliver_invitation overrides devise_invitable
      invitee.deliver_invitation

      mail = ActionMailer::Base.deliveries.last
      expect(mail.to).to include('newuser@example.com')
      expect(mail.subject).to include('A Data Management Plan in DMP Assistant has been shared with you')
      expect(mail.subject).to include("Un plan de gestion des données dans l'Assistant PGD a été partagé avec vous")
    end
  end
end
