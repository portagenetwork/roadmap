#
# frozen_string_literal: true

# spec/mailers/user_mailer_spec.rb
require 'rails_helper'

RSpec.describe UserMailer, type: :mailer do
  describe 'my_email' do
    let(:user) { User.create(email: Faker::Internet.email) }

    context 'when the user language is set to English' do
      before do
        @original_locale = I18n.locale
        I18n.locale = :'en-CA'
      end

      after do
        I18n.locale = @original_locale
      end

      let(:mail) { UserMailer.welcome_notification(user) }

      it 'renders the email subject in English' do
        expect(mail.subject).to include('Welcome to')
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

      let(:mail) { UserMailer.welcome_notification(user) }

      it 'renders the email subject in French' do
        expect(mail.subject).to include('Bienvenue sur ')
      end
    end
  end
end
