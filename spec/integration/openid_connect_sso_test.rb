require 'rails_helper'
require 'byebug'

RSpec.describe 'Openid_connection SSO', type: :feature, js: true do
  context 'with correct credentials' do
    before do
      create(:org, managed: false, is_other: true)
      @org = create(:org, managed: true)
      @identifier_scheme = create(:identifier_scheme,
                                  name: 'openid_connect',
                                  description: 'CILogon',
                                  active: true,
                                  identifier_prefix: 'https://www.cilogon.org/')

      Rails.application.env_config['devise.mapping'] = Devise.mappings[:user]
      Rails.application.env_config['omniauth.auth'] = OmniAuth.config.mock_auth[:openid_connect]
    end

    it 'creates account from external credentials' do
      visit root_path
      click_link 'Sign in with CILogon'

      identifier = Identifier.last
      expect(identifier.value).to eql('https://www.cilogon.org/12345')
      identifiable = identifier.identifiable
      expect(identifiable.email).to eql('user@organization.ca')
      expect(identifiable.firstname).to eql('John')
      expect(identifiable.surname).to eql('Doe')

      # Check logged in name
      byebug
      expect(page).to have_content('John Doe')
    end

    it 'links account from external credentails' do
      # Create existing user
      user = create(:user, :org_admin, org: @org, email: 'user@organization.ca')
      sign_in(user)
      # where do we find link credentials ?

      visit root_path
      byebug
      click_link 'Sign in with CILogon'
      identifier = Identifier.last
      expect(identifier.value).to eql('https://www.cilogon.org/12345')
      identifiable = identifier.identifiable
      # We will find the new user with the email specified above
      byebug
      expect(identifiable.email).to eql('user@organization.ca')

      # XXX Check for flash notice message linked successfully
    end
  end
end
