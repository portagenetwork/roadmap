# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'api/v2/plan_snapshots/_extension', type: :view do
  let(:template_hash) { PlanSnapshotValues.mock_extension_json.deep_symbolize_keys[:template] }
  let(:presenter) { Struct.new(:template).new(template_hash) }

  def rendered_json
    JSON.parse(rendered)
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
    phase = rendered_json['template']['phases'].first
    expected_phase = template_hash[:phases].first

    expect(phase['title']).to eq(expected_phase[:title])
    expect(phase['number']).to eq(expected_phase[:number])
  end

  it 'renders the section title, number, and modifiable' do
    section = rendered_json['template']['phases'].first['sections'].first
    expected_section = template_hash[:phases].first[:sections].first

    expect(section['title']).to eq(expected_section[:title])
    expect(section['number']).to eq(expected_section[:number])
    expect(section['modifiable']).to eq(expected_section[:modifiable])
  end

  it 'renders the question id, number, and text' do
    question = rendered_json['template']['phases'].first['sections'].first['questions'].first
    expected_question = template_hash[:phases].first[:sections].first[:questions].first

    expect(question['id']).to eq(expected_question[:id])
    expect(question['number']).to eq(expected_question[:number])
    expect(question['text']).to eq(expected_question[:text])
  end

  it 'renders the format id and title' do
    format = rendered_json['template']['phases'].first['sections'].first['questions'].first['format']
    expected_format = template_hash[:phases].first[:sections].first[:questions].first[:format]

    expect(format['id']).to eq(expected_format[:id])
    expect(format['title']).to eq(expected_format[:title])
  end

  it 'renders the answer text' do
    answer = rendered_json['template']['phases'].first['sections'].first['questions'].first['answer']
    expected_answer = template_hash[:phases].first[:sections].first[:questions].first[:answer]

    expect(answer['text']).to eq(expected_answer[:text])
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
      question = rendered_json['template']['phases'].first['sections'].first['questions'].first

      expect(question).not_to have_key('format')
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
      expected_title = template_hash[:phases].first[:title]

      expect(rendered_json['template']['phases'].first['title']).to eq(strip_tags(expected_title))
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
      expected_title = template_hash[:phases].first[:sections].first[:title]

      expect(rendered_json['template']['phases'].first['sections'].first['title']).to eq(strip_tags(expected_title))
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
      expected_text = template_hash[:phases].first[:sections].first[:questions].first[:text]
      text = rendered_json['template']['phases'].first['sections'].first['questions'].first['text']

      expect(text).to eq(sanitize(expected_text))
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
      expected_text = template_hash[:phases].first[:sections].first[:questions].first[:answer][:text]
      text = rendered_json['template']['phases'].first['sections'].first['questions'].first['answer']['text']

      expect(text).to eq(sanitize(expected_text))
    end
  end
end
