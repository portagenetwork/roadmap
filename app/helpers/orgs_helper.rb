# frozen_string_literal: true

# Helper methods for Orgs
module OrgsHelper
  EMAIL_PLACEHOLDER = '[Organisation Contact Email Placeholder]'
  PLAN_PLACEHOLDER = '[Plan Name Placeholder]'
  USER_PLACEHOLDER = ''

  # Displays a feedback message that the user can edit in the org/Request Feedback section
  #
  # org - The current Org who owns the feedback message being displayed
  # current_user - The current user we're showing feedback message to
  # feedack_message - The feedback message we're displaying
  # plan_name - Name of the plan we're displaying the feedback message for
  #
  # Returns String
  def display_editable_feedback_message(org, current_user, feedback_message, plan_name)
    email = org.contact_email || EMAIL_PLACEHOLDER
    username = current_user.name(false) || USER_PLACEHOLDER
    plan_title = plan_name || PLAN_PLACEHOLDER

    format(
      _(feedback_message),
      user_name: username, organisation_email: email, plan_name: plan_title
    )
  rescue KeyError, ArgumentError => e
    Rails.logger.error("Unable to display feedback message: #{e.message}")
    # /plans/:plan_id/request_feedback and /org/admin/:org_id/admin_edit both render the feedback_msg
    # If plan_name.nil?, then we are on /org/admin/:org_id/admin_edit
    if plan_name.nil?
      # Only render the error on the org admin page.
      message = _('Unable to render feedback message: ')
      message + _(e.message.to_s)
    end
  end

  # Displays a sample feedback message in the org/Request Feedback section
  # that is meant to serve as an example
  #
  # org - The current Org who owns the feedback message being displayed
  # current_user - The current user we're showing feedback message to
  #
  # Returns String
  def display_sample_feedback_message(org, current_user)
    email = org.contact_email || EMAIL_PLACEHOLDER
    username = current_user.name(false) || USER_PLACEHOLDER

    format(_('<p>Hello %{user_name},</p>' \
      'A member of your organisation will respond to your request to review your data management plan
       within 48 hours. ' \
      'If you have questions pertaining to this action please contact your local team at %{organisation_email}, ' \
      'or for assistance with DMP Assistant contact dmp-assistant@tech.alliancecan.ca.'), user_name: username,
                                                                                          organisation_email: email)
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
