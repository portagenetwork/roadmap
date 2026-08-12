# frozen_string_literal: true

require 'rails_helper'

RSpec.describe PlanSnapshots::FixityCheckService do
  let(:now) { Time.current }

  describe '#call' do
    subject(:service) { described_class.new(snapshot) }

    context 'when snapshot is not due' do
      let(:snapshot) { create(:plan_snapshot, :recently_checked) }

      it 'skips fixity check' do
        result = service.call

        expect(result[:status]).to eq(:skipped)
      end
    end

    context 'when snapshot is due and valid' do
      let(:snapshot) { create(:plan_snapshot, :stale) }

      before { snapshot.stubs(:fixity_check_passed?).returns(true) }

      it 'marks as ok and updates last checked timestamp' do
        result = service.call

        expect(result[:status]).to eq(:ok)
        expect(snapshot.reload.fixity_checked_at).to be_within(1.second).of(now)
      end
    end

    context 'when snapshot is due and invalid' do
      let(:snapshot) { create(:plan_snapshot, :stale) }
      let(:development_email) { Rails.configuration.x.organisation.development_email }

      before { snapshot.stubs(:fixity_check_passed?).returns(false) }

      it 'returns failed without updating timestamp' do
        ActionMailer::Base.deliveries.clear
        original_checked_at = snapshot.fixity_checked_at

        result = service.call

        expect(result[:status]).to eq(:failed)
        expect(snapshot.reload.fixity_checked_at).to be_within(1.second).of(original_checked_at)
        expect(ActionMailer::Base.deliveries.last.to).to eq([development_email])
        expect(ActionMailer::Base.deliveries.last.subject)
          .to include(PlanSnapshots::FailureNotifier::FIXITY_CHECK_FAILURE_MESSAGE)
      end
    end
  end
end
