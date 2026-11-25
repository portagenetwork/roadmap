# frozen_string_literal: true

module SessionsHelper
  def sign_in(user = :user, expect_signed_in: true)
    case user
    when User
      sign_in_as_user(user, expect_signed_in:)
    when Symbol
      sign_in_as_user(create(:user), expect_signed_in:)
    else
      raise ArgumentError, "Invalid argument user: #{user}"
    end
  end

  def sign_in_as_user(user, expect_signed_in: true)
    clear_cookies!
    visit root_path
    within '#sign-in-form' do
      fill_in 'Email', with: user.email
      fill_in 'Password', with: user.password.presence || 'StrongP@ssw0rd!@$%#'
      click_button 'Sign in'
    end
    return unless expect_signed_in

    expect(page).to have_css("a[href='#{destroy_user_session_path}']", visible: :all)
  end
end
