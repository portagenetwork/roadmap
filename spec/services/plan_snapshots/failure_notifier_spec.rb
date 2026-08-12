# frozen_string_literal: true

require 'rails_helper'

RSpec.describe PlanSnapshots::FailureNotifier do
  describe '.call' do
    let(:payload) { { plan_id: 123, user_id: 456 } }
    let(:message) { described_class::JSON_GENERATION_FAILURE_MESSAGE }
    let(:development_email) { Rails.configuration.x.organisation.development_email }

    before { ActionMailer::Base.deliveries.clear }

    it 'logs, emails and reports the failure' do
      Rails.logger.expects(:error).with(payload.merge(message: message))
      Rollbar.expects(:error).with(message, payload)

      described_class.call(
        message: message,
        payload: payload
      )

      expect(ActionMailer::Base.deliveries.last.to).to eq([development_email])
      expect(ActionMailer::Base.deliveries.last.subject).to include(message)
    end
  end
end
