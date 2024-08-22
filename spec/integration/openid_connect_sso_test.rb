require 'rails_helper'

RSpec.describe 'Openid_connection SSO', type: :feature do
  context 'with correct credentials' do
    before do
      create(:org, managed: false, is_other: true)
      @org = create(:org, managed: true)
      @identifier_scheme = create(:identifier_scheme,
                                  name: 'openid_connect',
                                  description: 'CILogon',
                                  active: true,
                                  identifier_prefix: 'https://www.cilogon.org/')
      # OmniAuth.config.add_mock(openid_connect: {
      #                            provider: 'openid_connect',
      #                            uid: '12345',
      #                            info:
      #     { email: 'user@organization.ca',
      #       first_name: 'John',
      #       last_name: 'Doe' }
      #                          })

      #                       OmniAuth.config.add_mock(openid_connect: {
      #                       'provider' => 'openid_connect',
      #                       'uid' => '12345',
      #                       'info' =>
      # { 'email' => 'user@organization.ca',
      #   'first_name' => 'John',
      #   'last_name' => 'Doe' }
      #                     })

      # OmniAuth.config.add_mock(:openid_connect, {
      #                            provider: 'openid_connect',
      #                            uid: '12345',
      #                            info: {
      #                              email: 'user@organization.ca',
      #                              first_name: 'John',
      #                              last_name: 'Doe'
      #                            }
      #                          })
      #       OmniAuth.config.mock_auth[:openid_connect] = OmniAuth::AuthHash.new({
      #                                                                       provider: 'openid_connect',
      #                                                                       uid: '12345',
      #                                                                       info:
      # { email: 'user@organization.ca',
      #   first_name: 'John',
      #   last_name: 'Doe' }
      Rails.application.env_config['devise.mapping'] = Devise.mappings[:user]
      Rails.application.env_config['omniauth.auth'] = OmniAuth.config.mock_auth[:openid_connect]
    end

    # it 'links external credentials with existing account' do
    # end

    it 'creates account from external credentials' do
      visit root_path
      click_link 'Sign in with CILogon'

      identifier = Identifier.last
      expect(identifier.value).to eql('https://www.cilogon.org/12345')
      identifiable = identifier.identifiable
      expect(identifiable.email).to eql('user@organization.ca')
      expect(identifiable.firstname).to eql('John')
      expect(identifiable.surname).to eql('Doe')

      # XXX Check notice message
    end

    it 'links account from external credentails' do
      # Create existing user
      create(:user, :org_admin, org: @org, email: 'user@organization.ca')
      visit root_path
      click_link 'Sign in with CILogon'
      identifier = Identifier.last
      expect(identifier.value).to eql('https://www.cilogon.org/12345')
      identifiable = identifier.identifiable
      # We will find the new user with the email specified above
      expect(identifiable.email).to eql('user@organization.ca')
    end
  end
end
