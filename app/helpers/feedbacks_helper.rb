# frozen_string_literal: true

# Helper methods for Feedback messages
module FeedbacksHelper
  def feedback_confirmation_default_subject
    _('%{application_name}: Your plan has been submitted for feedback')
  end

  def feedback_confirmation_default_message
    # This is the default feedback message
    _('<p>Hello %{user_name},</p>' \
      'A member of your organisation will respond to your request to review your data management plan within 48 hours. ' \
      'If you have questions pertaining to this action please contact your local team at %{organisation_email}, ' \
      'or for assistance with DMP Assistant contact dmp-assistant@tech.alliancecan.ca.')
  end

  def feedback_constant_to_text(text, user, plan, org)
    format(_(text.to_s), application_name: ApplicationService.application_name, user_name: user.name(false),
                         plan_name: plan.title, organisation_email: org.contact_email)
  end
end
