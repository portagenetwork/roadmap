# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'shared/export/plan_snapshot.erb', type: :view do
  let(:snapshot) { create(:plan_snapshot) }
  let(:extension_json) { PlanSnapshotValues.mock_extension_json.deep_dup }

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

  it 'renders template hierarchy and answered content' do
    expect(rendered).to include('Phase 1')
    expect(rendered).to include('Section 1')
    expect(rendered).to include('What is your project about?')
    expect(rendered).to include('Example answer')
  end

  context 'when a question is unanswered' do
    let(:extension_json) do
      json = PlanSnapshotValues.mock_extension_json.deep_dup
      json['template']['phases'][0]['sections'][0]['questions'][0]['answer']['text'] = ''
      json
    end

    it 'renders the unanswered message' do
      expect(rendered).to include('Question not answered.')
    end
  end

  context 'when question and answer contain script tags' do
    let(:extension_json) do
      json = PlanSnapshotValues.mock_extension_json.deep_dup
      question = json['template']['phases'][0]['sections'][0]['questions'][0]
      question['text'] = '<script></script>Question text'
      question['answer']['text'] = '<script></script>Answer text'
      json
    end

    it 'sanitizes script tags' do
      expect(rendered).to include('Question text')
      expect(rendered).to include('Answer text')
      expect(rendered).not_to include('<script>')
    end
  end
end
