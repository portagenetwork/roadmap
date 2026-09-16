# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Api::V2::PlanPresenter do
  describe '#initialize(plan:, complete:, for_common_madmp_api:)' do
    it 'stores the Common MaDMP flag when enabled' do
      plan = create(:plan, :creator)

      presenter = described_class.new(plan: plan, for_common_madmp_api: true)

      expect(presenter.instance_variable_get(:@for_common_madmp_api)).to be(true)
    end

    it 'leaves the Common MaDMP flag falsey by default' do
      plan = create(:plan, :creator)

      presenter = described_class.new(plan: plan)

      expect(presenter.instance_variable_get(:@for_common_madmp_api)).to be(false)
    end

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
