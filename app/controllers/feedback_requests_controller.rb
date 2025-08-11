# frozen_string_literal: true

# Controller that handles requests for Admin Feedback
class FeedbackRequestsController < ApplicationController
  include FeedbacksHelper

  after_action :verify_authorized

  ALERT = _('Unable to submit your request for feedback at this time.')
  ERROR = _('An error occurred when requesting feedback for this plan.')

  def create
    @plan = Plan.find(params[:plan_id])
    authorize @plan, :request_feedback?
    begin
      if @plan.request_feedback(current_user)
        redirect_to request_feedback_plan_path(@plan), notice: _(request_feedback_flash_notice)
      else
        redirect_to request_feedback_plan_path(@plan), alert: ALERT
      end
    rescue StandardError
      redirect_to request_feedback_plan_path(@plan), alert: ERROR
    end
  end

  private

  # Flash notice for successful feedback requests
  #
  # Returns String
  def request_feedback_flash_notice
    # This is the flash notice that is shown after a user clicks "Request Feedback"
    # when creating a plan

    text = "<p>Your plan \"%{plan_name}\" has been submitted for feedback from an
       administrator at your organisation. " \
      "If you have questions pertaining to this action, please contact us
      at %{organisation_email}.</p>"

    feedback_constant_to_text(text, current_user, @plan, current_user.org)
  end
end
