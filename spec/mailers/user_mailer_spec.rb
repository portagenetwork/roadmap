# frozen_string_literal: true

# spec/mailers/user_mailer_spec.rb
require 'rails_helper'

RSpec.describe UserMailer, type: :mailer do
  # For ensuring I18n.locale value remains intact.
  let(:original_locale) { I18n.locale }

  before(:all) do
    # TODO: Update spec/support/locales.rb to actually use DMP Assistant's locales.
    @original_locales = I18n.available_locales
    I18n.available_locales = %i[en-CA fr-CA]
  end

  after(:all) do
    I18n.available_locales = @original_locales
  end

  describe 'UserMailer Welcome Email' do
    let(:user) { create(:user) }

    context '.welcome_notification email contents' do
      let(:mail) { UserMailer.welcome_notification(user) }

      it 'Renders the bilingual welcome message as expected' do
        expect(mail.to).to include(user.email)
        # Email subject is bilingual
        expect(mail.subject).to eq("Welcome to DMP Assistant / Bienvenue sur l'Assistant PGD")
        # Email body has both English and French sections
        expect(mail.body).to include('Welcome to DMP Assistant')
        # Use Nokogiri to escape HTML (')
        html = Nokogiri::HTML(mail.body.to_s)
        expect(html.text).to include("Bienvenue sur l'Assistant PGD")
        # I18n.locale value remains intact
        expect(I18n.locale).to eq(original_locale)
      end
    end
  end

  describe 'UserMailer Sharing Email' do
    let!(:org)     { create(:org, :organisation, name: 'Test org') }
    let!(:inviter) { create(:user, org: org) }

    shared_examples 'localized .sharing_notification email' do |expected_subject, expected_body|
      # :role and :mail depend on :user and :plan, so define them here
      let!(:role) { create(:role, :creator, :active, plan: plan, user: user) }
      let(:mail)  { UserMailer.sharing_notification(role, user, inviter: inviter) }

      it 'renders the expected email content' do
        expect(mail.to).to include(user.email)
        expect(mail.subject).to eq(expected_subject)
        expect(mail.body).to include(expected_body)
        # localized email has not changed I18n.locale
        expect(I18n.locale).to eq(original_locale)
      end
    end

    let!(:plan) { create(:plan, org: org, visibility: 'publicly_visible') }

    context 'en-CA locale' do
      let!(:language) { create(:language, abbreviation: 'en-CA') }
      let!(:user)     { create(:user, language: language, org: org) }

      include_examples 'localized .sharing_notification email',
                       'A Data Management Plan in DMP Assistant has been shared with you',
                       'has invited you to contribute'
    end

    context 'fr-CA locale' do
      let!(:language) { create(:language, abbreviation: 'fr-CA') }
      let!(:user)     { create(:user, language: language, org: org) }

      include_examples 'localized .sharing_notification email',
                       'Un plan de gestion des données dans Assistant PGD a été partagé avec vous',
                       'Si vous ne souhaitez pas accepter l’invitation'
    end
  end

  describe 'UserMailer Plan Snapshot Failure Alert Email' do
    let(:message) { 'Plan snapshot JSON generation failed' }
    let(:payload) { { plan_id: 123, errors: { rda_json: ['Missing required field'] } } }
    let(:mail) { UserMailer.plan_snapshot_failure_alert(message: message, payload: payload) }

    it 'sends to development email with failure details' do
      expect(mail.to).to eq([Rails.configuration.x.organisation.development_email])
      expect(mail.subject).to include(fmessage)
      expect(mail.body.to_s).to include(message)
      expect(mail.body.to_s).to include('plan_id')
      expect(mail.body.to_s).to include('123')
    end
  end
end
