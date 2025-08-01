# frozen_string_literal: true

# spec/mailers/user_mailer_spec.rb
require 'rails_helper'

RSpec.describe UserMailer, type: :mailer do
  describe 'UserMailer Welcome Email' do
    let(:user) { create(:user) }

    context '.welcome_notification email contents' do
      let(:mail) { UserMailer.welcome_notification(user) }

      it 'renders the correct email subject' do
        expect(mail.subject).to eq("Welcome to DMP Assistant / Bienvenue sur l'Assistant PGD")
      end
    end
  end

  describe 'UserMailer Sharing Email' do
    let!(:org) { create(:org, :organisation, name: 'Test org') }
    let!(:inviter) { create(:user, org: org) }

    context 'when the user language is set to English' do
      before do
        @original_locale = I18n.locale
        I18n.locale = :'en-CA'
      end

      after do
        I18n.locale = @original_locale
      end

      let!(:user) { create(:user, language: create(:language, abbreviation: 'en-CA'), org: org) }
      let!(:plan) { create(:plan, org: org, visibility: 'publicly_visible') }
      let!(:role) { create(:role, :creator, :active, plan: plan, user: user) }

      let!(:mail) { UserMailer.sharing_notification(role, user, inviter: inviter) }

      it 'renders the email subject in English' do
        Rails.configuration.x.application.name = 'Foo'
        expect(mail.subject).to include('A Data Management Plan in Foo has been shared with you')
      end
    end

    context 'when the user language is set to French' do
      before do
        @original_locale = I18n.locale
        I18n.locale = :'fr-CA'
      end

      after do
        I18n.locale = @original_locale
      end

      let!(:user) { create(:user, language: create(:language, abbreviation: 'fr-CA'), org: org) }
      let!(:plan) { create(:plan, org: org, visibility: 'publicly_visible') }
      let!(:role) { create(:role, :creator, :active, plan: plan, user: user) }

      let!(:mail) { UserMailer.sharing_notification(role, user, inviter: inviter) }

      it 'renders the email subject in French' do
        Rails.configuration.x.application.name = 'Bar'
        expect(mail.subject).to include('Un plan de gestion des données dans Bar a été partagé avec vous')
      end
    end
  end
end
