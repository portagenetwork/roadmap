#
# frozen_string_literal: true

# spec/mailers/user_mailer_spec.rb
require 'rails_helper'

RSpec.describe UserMailer, type: :mailer do
  describe 'UserMailer methods' do
    let(:user) { create(:user) }

    context '.welcome_notification email contents' do
      let(:mail) { UserMailer.welcome_notification(user) }

      it 'renders the correct email subject' do
        expect(mail.subject).to eq("Welcome to DMP Assistant / Bienvenue sur l'Assistant PGD")
      end
    end
  end
end
