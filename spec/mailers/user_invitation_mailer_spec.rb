# frozen_string_literal: true

# spec/mailers/user_invitation_mailer_spec.rb
require 'rails_helper'

RSpec.describe 'User invitation email', type: :mailer do
  describe 'Invitation Email to User Not in DB' do
    let(:inviter) { create(:user) }
    let(:invitee_email) { 'newuser@example.com' }
    # For ensuring I18n.locale value remains intact.
    let(:original_locale) { I18n.locale }

    before do
      ActionMailer::Base.deliveries.clear
      # TODO: Update spec/support/locales.rb to actually use DMP Assistant's locales.
      @original_locales = I18n.available_locales
      I18n.available_locales = %i[en-CA fr-CA]
    end

    after do
      I18n.available_locales = @original_locales
    end

    it 'sends an invitation with the expected content' do
      invite_new_user
      mail = ActionMailer::Base.deliveries.last
      expect(mail.to).to include(invitee_email)
      # The subject line is bilingual
      expect(mail.subject).to eq('A Data Management Plan in DMP Assistant has been shared with you / ' \
                                 "Un plan de gestion des données dans l'Assistant PGD a été partagé avec vous")
      # The body is bilingual
      # (TODO: Fix this generic name greeting)
      expect(mail.body).to include('Hello First Name Surname')
      expect(mail.body).to include('Bonjour First Name Surname')
      # I18n.locale value remains intact
      expect(I18n.locale).to eq(original_locale)
    end
  end

  private

  def invite_new_user
    # This code is copied from RolesController#create to simulate its User.invite! behavior.
    # The controller action is large, so copying the code here is a pragmatic testing approach
    User.invite!({ email: invitee_email,
                   firstname: _('First Name'),
                   surname: _('Surname'),
                   org: inviter.org },
                 inviter)
  end
end
