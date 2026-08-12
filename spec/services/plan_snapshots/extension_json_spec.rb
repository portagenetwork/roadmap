# frozen_string_literal: true

require 'rails_helper'
require_relative '../../support/mocks/plan_snapshot_values'

RSpec.describe PlanSnapshots::ExtensionJson do
  let(:extension_json) { PlanSnapshotValues.mock_extension_json }
  subject(:extension) { described_class.new(extension_json: extension_json) }
  let(:template) { extension.template }

  let(:template_json) { extension_json['template'] }
  let(:phase_json) { template_json['phases'].first }
  let(:section_json) { phase_json['sections'].first }
  let(:question_json) { section_json['questions'].first }
  let(:format_json) { question_json['format'] }
  let(:answer_json) { question_json['answer'] }

  describe '#template' do
    it 'exposes template attributes' do
      expect(template.id).to eq(template_json['id'])
      expect(template.title).to eq(template_json['title'])
      expect(template.version).to eq(template_json['version'])
    end

    it 'wraps phases, sections, questions, formats, and answers' do
      phase = template.phases.first
      section = phase.sections.first
      question = section.questions.first

      aggregate_failures do
        expect(phase.title).to eq(phase_json['title'])
        expect(phase.number).to eq(phase_json['number'])

        expect(section.title).to eq(section_json['title'])
        expect(section.number).to eq(section_json['number'])
        expect(section.modifiable).to eq(section_json['modifiable'])

        expect(question.id).to eq(question_json['id'])
        expect(question.number).to eq(question_json['number'])
        expect(question.text).to eq(question_json['text'])

        expect(question.format.id).to eq(format_json['id'])
        expect(question.format.title).to eq(format_json['title'])

        expect(question.answer.text).to eq(answer_json['text'])
        expect(question.answer.question_options).to eq([])
      end
    end

    context 'when the answer includes selected question options' do
      before do
        question_json['answer']['question_options'] = [{ 'id' => 10, 'text' => 'Selected option' }]
      end

      it 'wraps option id and text' do
        question = template.phases.first.sections.first.questions.first
        option = question.answer.question_options.first

        expect(option.id).to eq(10)
        expect(option.text).to eq('Selected option')
      end
    end

    context 'when a question has no format' do
      before do
        question_json.delete('format')
      end

      it 'returns nil' do
        question = template.phases.first.sections.first.questions.first

        expect(question.format).to be_nil
      end
    end
  end

  context 'when extension_json is nil' do
    let(:extension_json) { nil }

    it 'returns an empty template wrapper' do
      aggregate_failures do
        expect(template.id).to be_nil
        expect(template.title).to be_nil
        expect(template.version).to be_nil
        expect(template.phases).to eq([])
      end
    end
  end
end
