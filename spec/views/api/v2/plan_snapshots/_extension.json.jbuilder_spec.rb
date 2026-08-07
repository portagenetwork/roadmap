# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'api/v2/plan_snapshots/_extension', type: :view do
  let(:template_hash) { PlanSnapshotValues.mock_extension_json.deep_symbolize_keys[:template] }
  let(:presenter) { Struct.new(:template).new(template_hash) }

  def rendered_json
    JSON.parse(rendered)
  end

  def json_phase
    rendered_json['template']['phases'].first
  end

  def json_section
    json_phase['sections'].first
  end

  def json_question
    json_section['questions'].first
  end

  def expected_phase
    template_hash[:phases].first
  end

  def expected_section
    expected_phase[:sections].first
  end

  def expected_question
    expected_section[:questions].first
  end

  before do
    render partial: 'api/v2/plan_snapshots/extension', locals: { presenter: presenter }
  end

  it 'renders the template id, title, and version' do
    template = rendered_json['template']

    expect(template['id']).to eq(template_hash[:id])
    expect(template['title']).to eq(template_hash[:title])
    expect(template['version']).to eq(template_hash[:version])
  end

  it 'renders the phase title and number' do
    expect(json_phase['title']).to eq(expected_phase[:title])
    expect(json_phase['number']).to eq(expected_phase[:number])
  end

  it 'renders the section title, number, and modifiable' do
    expect(json_section['title']).to eq(expected_section[:title])
    expect(json_section['number']).to eq(expected_section[:number])
    expect(json_section['modifiable']).to eq(expected_section[:modifiable])
  end

  it 'renders the question id, number, and text' do
    expect(json_question['id']).to eq(expected_question[:id])
    expect(json_question['number']).to eq(expected_question[:number])
    expect(json_question['text']).to eq(expected_question[:text])
  end

  it 'renders the format id and title' do
    expect(json_question['format']['id']).to eq(expected_question[:format][:id])
    expect(json_question['format']['title']).to eq(expected_question[:format][:title])
  end

  it 'renders the answer text' do
    expect(json_question['answer']['text']).to eq(expected_question[:answer][:text])
    expect(json_question['answer']['question_options']).to eq([])
  end

  context 'when an answer has selected options' do
    let(:template_hash) do
      hash = super().dup
      question = hash[:phases].first[:sections].first[:questions].first
      question = question.merge(answer: { text: '', question_options: [{ id: 7, text: 'Option A' }] })
      section = hash[:phases].first[:sections].first.merge(questions: [question])
      hash[:phases] = [hash[:phases].first.merge(sections: [section])]
      hash
    end

    it 'renders answer question options' do
      options = json_question['answer']['question_options']

      expect(options).to eq([{ 'id' => 7, 'text' => 'Option A' }])
    end
  end

  context 'when a question has no format' do
    let(:template_hash) do
      hash = super().dup
      question = hash[:phases].first[:sections].first[:questions].first.merge(format: nil)
      section = hash[:phases].first[:sections].first.merge(questions: [question])
      hash[:phases] = [hash[:phases].first.merge(sections: [section])]
      hash
    end

    it 'omits the format key' do
      expect(json_question).not_to have_key('format')
    end
  end

  context 'when the template title contains HTML' do
    let(:template_hash) { super().merge(title: '<b>Test</b> Template') }

    it 'strips tags from the title' do
      expect(rendered_json['template']['title']).to eq(strip_tags(template_hash[:title]))
    end
  end

  context 'when a phase title contains HTML' do
    let(:template_hash) do
      hash = super().dup
      hash[:phases] = [hash[:phases].first.merge(title: '<i>Phase</i> 1')]
      hash
    end

    it 'strips tags from the phase title' do
      expect(json_phase['title']).to eq(strip_tags(expected_phase[:title]))
    end
  end

  context 'when a section title contains HTML' do
    let(:template_hash) do
      hash = super().dup
      section = hash[:phases].first[:sections].first.merge(title: '<i>Section</i> 1')
      hash[:phases] = [hash[:phases].first.merge(sections: [section])]
      hash
    end

    it 'strips tags from the section title' do
      expect(json_section['title']).to eq(strip_tags(expected_section[:title]))
    end
  end

  context 'when a question text contains a script tag' do
    let(:template_hash) do
      hash = super().dup
      question = hash[:phases].first[:sections].first[:questions].first
                              .merge(text: '<script>x</script>What is your plan?')
      section = hash[:phases].first[:sections].first.merge(questions: [question])
      hash[:phases] = [hash[:phases].first.merge(sections: [section])]
      hash
    end

    it 'strips the script tag from the question text' do
      expect(json_question['text']).to eq(sanitize(expected_question[:text]))
    end
  end

  context 'when an answer text contains a script tag' do
    let(:template_hash) do
      hash = super().dup
      question = hash[:phases].first[:sections].first[:questions].first
                              .merge(answer: { text: '<script>x</script>Test answer' })
      section = hash[:phases].first[:sections].first.merge(questions: [question])
      hash[:phases] = [hash[:phases].first.merge(sections: [section])]
      hash
    end

    it 'strips the script tag from the answer text' do
      expect(json_question['answer']['text']).to eq(sanitize(expected_question[:answer][:text]))
    end
  end
end
