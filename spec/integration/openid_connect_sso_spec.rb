# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Openid_connection SSO', type: :feature do
  context 'with correct credentials' do
    before do
      create(:org, managed: false, is_other: true)
      @org = create(:org, managed: true)
      @identifier_scheme = create(:identifier_scheme, :openid_connect)

      # Adding this identifier scheme as it is needed in view but we are not testing for it
      create(:identifier_scheme,
             name: 'orcid',
             description: 'ORCID',
             active: true,
             identifier_prefix: 'https://orcid.org/')

      Rails.application.env_config['devise.mapping'] = Devise.mappings[:user]
      Rails.application.env_config['omniauth.auth'] = OmniAuth.config.mock_auth[:openid_connect]
    end

    it 'creates account from external credentials', :js do
      visit root_path
      click_link 'Sign in with institutional or social ID'

      identifier = Identifier.last
      expect(identifier.value).to eql('https://www.cilogon.org/12345')
      identifiable = identifier.identifiable
      expect(identifiable.email).to eql('user@organization.ca')
      expect(identifiable.firstname).to eql('John')
      expect(identifiable.surname).to eql('Doe')

      # Check logged in name
      expect(page).to have_content('John Doe')
    end

    scenario 'A user attempts to sign in via the "Sign in with institutional
              or social ID" button with an email that is not currently linked
              to any account. The chosen SSO email matches an existing user account email.', :js do
      user = create(:user, :org_admin, org: @org, email: 'user@organization.ca',
                                       firstname: 'DMP Name', surname: 'DMP Lastname')
      visit root_path
      click_link 'Sign in with institutional or social ID'

      # The user is signed in
      expect(current_path).to eql(plans_path)
      # The SSO email is linked to the user
      expect(user.identifiers.count).to eql(1)
      expect(Identifier.last.identifiable).to eql(user)
    end

    it 'links account from external credentails', :js do
      # Create existing user
      user = create(:user, :org_admin, org: @org, email: 'user@organization.ca', firstname: 'DMP Name',
                                       surname: 'DMP Lastname')
      sign_in(user)

      find('#user-menu').click
      click_link('Edit profile')
      click_link('Link your institutional credentials')

      identifier = Identifier.last
      expect(identifier.value).to eql('https://www.cilogon.org/12345')
      identifiable = identifier.identifiable
      # We will find the new user with the email specified above
      # Names will be different as there is already an account in our system
      expect(identifiable.email).to eql('user@organization.ca')
      expect(identifiable.firstname).to_not eql('John')
      expect(identifiable.surname).to_not eql('Doe')

      # XXX Check for flash notice message linked successfully
      # expect(page).to have_content('Linked succesfully')
    end
  end
end
