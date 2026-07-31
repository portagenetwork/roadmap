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

    it 'formats option-based answers correctly in complete_plan_data' do
      question_format = create(:question_format, option_based: true)
      plan = create(:plan, :creator)

      question = build(:question, question_format: question_format)
      question.question_options << build(:question_option, text: 'Option A')
      question.question_options << build(:question_option, text: 'Option B')

      create(:answer, plan: plan, question: question, question_options: question.question_options, text: nil)

      presenter = described_class.new(plan: plan, complete: true)
      item = presenter.complete_plan_data.find { |i| i[:id] == question.id }

      expect(item[:answer]).to eq('Option A, Option B')
    end
  end
end
