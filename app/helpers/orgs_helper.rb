# frozen_string_literal: true

# Helper methods for Orgs
module OrgsHelper
  include FeedbacksHelper

  EMAIL_PLACEHOLDER = '[Organisation Contact Email Placeholder]'

  # Displays a feedback message that the user can edit in the org/Request Feedback section
  #
  # org - The current Org who owns the feedback message being displayed
  # current_user - The current user we're showing feedback message to
  # feedack_message - The feedback message we're displaying
  # plan_name - Name of the plan we're displaying the feedback message for
  def display_editable_feedback_message(org, current_user, feedback_message, plan_name)
    email = org.contact_email || EMAIL_PLACEHOLDER

    format(
      _(feedback_message),
      user_name: current_user.name(false), organisation_email: email, plan_name: plan_name
    )
  rescue KeyError, ArgumentError => e
    Rails.logger.error("Unable to display feedback message: #{e.message}")
  end

  # Displays a sample feedback message in the org/Request Feedback section
  # that is meant to serve as an example
  def display_sample_feedback_message(org, current_user)
    email = org.contact_email || EMAIL_PLACEHOLDER

    # feedback_confirmation_default_message is taken from feedbacks_helper.rb
    format(feedback_confirmation_default_message, user_name: current_user.name(false), organisation_email: email)
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
