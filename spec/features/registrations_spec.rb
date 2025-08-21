# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Registrations', type: :feature do
  let!(:org) { create(:org) }
  let!(:language) { Language.default || create(:language, abbreviation: 'reg-feat', default_language: true) }

  let(:user_attributes) { attributes_for(:user) }

  scenario 'User creates a new acccount', :js do
    # Setup
    visit root_path

    # Action
    click_link 'Create account'
    within('#create-account-form') do
      fill_in 'First Name', with: user_attributes[:firstname]
      fill_in 'Last Name', with: user_attributes[:surname]
      fill_in 'Email', with: user_attributes[:email]
      choose_suggestion('new_user_org_name', org)
      fill_in 'Password', with: user_attributes[:password]
      check 'Show password'
      check 'I accept the terms and conditions'
    end
    click_button 'Create account'

    # Expectations
    expect(current_path).to eql(root_path)
    expect(page).to have_text('A message with a confirmation link has been sent to your email address.')
    expect(User.count).to eq(1)
  end

  scenario 'User attempts to create a new acccount with invalid atts', :js do
    # Setup
    visit root_path

    # Action
    click_link 'Create account'
    within('#create-account-form') do
      fill_in 'First Name', with: user_attributes[:firstname]
      fill_in 'Last Name', with: user_attributes[:surname]
      fill_in 'Email', with: 'invalid-email'
      choose_suggestion('new_user_org_name', org)
      fill_in 'Password', with: user_attributes[:password]
      check 'Show password'
      check 'I accept the terms and conditions'
    end
    click_button 'Create account'

    # Expectations
    expect(current_path).to eql(root_path)
    expect(User.count).to be_zero
  end

  scenario 'User attempts to login with weak and strong passwords', :js do
    # Setup
    visit root_path

    # Action
    click_link 'Create account'
    within('#create-account-form') do
      # Start with a very weak password
      # Only meets one requirement (lowercase letters)
      fill_in 'Password', with: 'abc'
    end

    # Check rule indicators
    # Only 1 out of 5 should be a check mark
    within('#password-requirements') do
      expect(page).to have_css('.fa-circle-check', count: 1)
      expect(page).to have_css('.fa-circle-xmark', count: 4)
    end

    within('#create-account-form') do
      # Try a moderate password
      # Meets three requirements (lowercase and uppercase letters + Number)
      fill_in 'Password', with: 'Pass4'
    end

    # Check rule indicators
    within('#password-requirements') do
      expect(page).to have_css('.fa-circle-check', count: 3)
      expect(page).to have_css('.fa-circle-xmark', count: 2)
    end

    within('#create-account-form') do
      # Fill in a strong password
      fill_in 'Password', with: 'StrongP@ssw0rd!@$%#'
    end

    # Check rule indicators
    # All 5 requirements should be met
    within('#password-requirements') do
      expect(page).to have_css('.fa-circle-check', count: 5)
      expect(page).to have_css('.fa-circle-xmark', count: 0)
    end
  end
end
