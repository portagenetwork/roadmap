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
        redirect_to request_feedback_plan_path(@plan), notice: request_feedback_flash_notice(@plan, current_user.org)
      else
        redirect_to request_feedback_plan_path(@plan), alert: ALERT
      end
    rescue StandardError
      redirect_to request_feedback_plan_path(@plan), alert: ERROR
    end
  end
end
