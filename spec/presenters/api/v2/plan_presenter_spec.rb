# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Api::V2::PlanPresenter do
  describe '#initialize(plan:, complete:)' do
    it 'includes only answered questions in complete_plan_data' do
      plan = create(:plan, :creator)
      answered = create(:answer, plan: plan, text: 'A non-blank answer')
      unanswered = create(:answer, plan: plan, text: '')

      presenter = described_class.new(plan: plan, complete: true)

      ids = presenter.complete_plan_data.pluck(:id)
      expect(ids).to include(answered.question_id)
      expect(ids).not_to include(unanswered.question_id)
    end
  end
end
