# frozen_string_literal: true

# Helper methods for Feedback messages
module FeedbacksHelper
  EMAIL_PLACEHOLDER = '[Organisation Contact Email Placeholder]'

  def feedback_confirmation_default_subject
    _('%{application_name}: Your plan has been submitted for feedback')
  end

  def feedback_confirmation_default_message
    # This is the default feedback message
    _('<p>Hello %{user_name},</p>' \
      'A member of your organisation will respond to your request to review your data management plan
       within 48 hours. ' \
      'If you have questions pertaining to this action please contact your local team at %{organisation_email}, ' \
      'or for assistance with DMP Assistant contact dmp-assistant@tech.alliancecan.ca.')
  end

  def feedback_constant_to_text(text, user, plan, org)
    format(_(text.to_s), application_name: ApplicationService.application_name, user_name: user.name(false),
                         plan_name: plan.title, organisation_email: org.contact_email)
  end

  # Displays a feedback message that the user can edit in the org/Request Feedback section
  #
  # org - The current Org who owns the feedback message being displayed
  # current_user - The current user we're showing feedback message to
  # feedack_message - The feedback message we're displaying
  # plan_name - Name of the plan we're displaying the feedback message for
  def display_editable_feedback_message(org, feedback_message, plan_name)
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
  def display_sample_feedback_message(org)
    email = org.contact_email || EMAIL_PLACEHOLDER

    format(feedback_confirmation_default_message, user_name: current_user.name(false), organisation_email: email)
  end
end
