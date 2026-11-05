# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'org_admin/conditions/_existing_condition_display.html.erb', type: :view do
  let(:question) { create(:question, :checkbox, options: 2) }
  let(:target_questions) { create_list(:question, 2) }
  let(:condition) do
    {
      question_option_id: question.question_options.map { |option| option.id.to_s },
      action_type: 'remove',
      remove_question_id: target_questions.map { |target| target.id.to_s }
    }
  end

  before do
    render partial: 'org_admin/conditions/existing_condition_display',
           locals: { condition: condition, condition_no: 0, name_start: 'conditions[0]' }
  end

  it 'renders a separate hidden field for each selected option' do
    condition[:question_option_id].each do |option_id|
      expect(rendered).to have_selector(
        "input[type='hidden'][name='conditions[0][question_option][]'][value='#{option_id}']",
        visible: :all
      )
    end
  end

  it 'renders a separate hidden field for each target question' do
    condition[:remove_question_id].each do |question_id|
      expect(rendered).to have_selector(
        "input[type='hidden'][name='conditions[0][remove_question_id][]'][value='#{question_id}']",
        visible: :all
      )
    end
  end
end
