# frozen_string_literal: true

# Helper methods for Orgs
module OrgsHelper
  EMAIL_PLACEHOLDER = '[Organisation Contact Email Placeholder]'
  PLAN_PLACEHOLDER = '[Plan Name Placeholder]'
  USER_PLACEHOLDER = ''
  # Displays a feedback message
  #
  # org - The current Org who owns the feedback message being displayed
  # current_user - The current user we're showing feedback message to
  #
  # Returns String
  def display_feedback_message(org, current_user, feedback_message)
    email = org.contact_email || EMAIL_PLACEHOLDER
    username = current_user.name(false) || USER_PLACEHOLDER
    format(
      _(feedback_message),
      user_name: username, organisation_email: email, plan_name: PLAN_PLACEHOLDER
    )
  rescue KeyError, ArgumentError => e
    Rails.logger.error("Unable to display feedback message: #{e.message}")
    message = _('Unable to render feedback message: ')
    message + _(e.message.to_s)
  end

  # The preferred logo url for the current configuration. If DRAGONFLY_AWS is true, return
  # the remote_url, otherwise return the url
  def logo_url_for_org(org)
    if ENV.fetch('DRAGONFLY_AWS', nil) == 'true'
      org.logo.remote_url
    else
      org.logo.url
    end
  end
end
