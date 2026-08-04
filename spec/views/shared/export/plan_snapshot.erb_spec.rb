# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'shared/export/plan_snapshot.erb', type: :view do
  let(:snapshot) { create(:plan_snapshot) }
  let(:extension_json) { PlanSnapshotValues.mock_extension_json.deep_dup }
  let(:phase) { extension_json['template']['phases'].first }
  let(:section) { phase['sections'].first }
  let(:question) { section['questions'].first }

  before do
    snapshot.update_column(:extension_json, extension_json)
    snapshot.reload

    assign(:snapshot, snapshot)
    assign(:formatting, Settings::Template::DEFAULT_SETTINGS)
    assign(:investigators, snapshot.contributors.with_role(:investigation))
    assign(:data_curators, snapshot.contributors.with_role(:data_curation))
    assign(:project_administrators, snapshot.contributors.with_role(:project_administration))
    assign(:other_contributors, snapshot.contributors.with_role(:other))

    render template: 'shared/export/plan_snapshot'
  end

  def first_question(json)
    json['template']['phases'][0]['sections'][0]['questions'][0]
  end

  it 'renders template hierarchy and answered content' do
    expect(rendered).to include(phase['title'])
    expect(rendered).to include(section['title'])
    expect(rendered).to include(question['text'])
    expect(rendered).to include(question['answer']['text'])
  end

  context 'when a question is unanswered' do
    let(:extension_json) do
      json = PlanSnapshotValues.mock_extension_json.deep_dup
      first_question(json)['answer']['text'] = ''
      json
    end

    it 'renders the unanswered message' do
      expect(rendered).to include('Question not answered.')
    end
  end

  context 'when question and answer contain script tags' do
    let(:script_tag) { '<script></script>' }
    let(:question_text) { 'Question text' }
    let(:answer_text) { 'Answer text' }

    let(:extension_json) do
      json = PlanSnapshotValues.mock_extension_json.deep_dup
      q = first_question(json)
      q['text'] = "#{script_tag}#{question_text}"
      q['answer']['text'] = "#{script_tag}#{answer_text}"
      json
    end

    it 'sanitizes script tags' do
      expect(rendered).to include(question_text)
      expect(rendered).to include(answer_text)
      expect(rendered).not_to include('<script>')
    end
  end
end
