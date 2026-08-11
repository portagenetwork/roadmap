# frozen_string_literal: true

module PlanSnapshots
  # Centralized failure alerting for plan snapshot workflows.
  class FailureNotifier
    JSON_GENERATION_FAILURE_MESSAGE = 'Plan snapshot JSON generation failed'
    FIXITY_CHECK_FAILURE_MESSAGE = 'PlanSnapshot fixity check failed'

    def self.call(message:, payload:)
      new(message: message, payload: payload).call
    end

    def initialize(message:, payload:)
      @message = message
      @payload = payload
    end

    def call
      Rails.logger.error(payload.merge(message: message))
      Rollbar.error(message, payload)

      UserMailer.plan_snapshot_failure_alert(
        message: message,
        payload: payload
      ).deliver_now
    end

    private

    attr_reader :message, :payload
  end
end
