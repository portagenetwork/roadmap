# frozen_string_literal: true

require 'rails_helper'
require_relative '../../support/mocks/plan_snapshot_values'

RSpec.describe PlanSnapshots::ExtensionJsonValidator do
  subject(:validator) { described_class.new(extension_json) }

  let(:extension_json) { PlanSnapshotValues.mock_extension_json }

  describe '#valid?' do
    it 'returns true when template has id/title and at least one question is answered' do
      expect(validator.valid?).to be(true)
    end

    it 'returns false when template id is missing' do
      expect(validator_for_modified_json do |json|
        template_json(json).delete('id')
      end.valid?).to be(false)
    end

    it 'returns false when template title is missing' do
      expect(validator_for_modified_json do |json|
        template_json(json).delete('title')
      end.valid?).to be(false)
    end

    it 'returns false when no questions have an answer' do
      expect(validator_for_modified_json do |json|
        blank_all_answers(json)
      end.valid?).to be(false)
    end

    it 'returns false when a question has no answer key at all' do
      expect(validator_for_modified_json do |json|
        remove_all_answers(json)
      end.valid?).to be(false)
    end

    it 'returns false when there are no phases at all' do
      expect(validator_for_modified_json do |json|
        template_json(json)['phases'] = []
      end.valid?).to be(false)
    end

    it 'returns true when only one of several questions is answered' do
      expect(validator_for_modified_json do |json|
        add_unanswered_question(json)
      end.valid?).to be(true)
    end
  end

  context 'when extension_json is nil' do
    let(:extension_json) { nil }

    it 'returns false' do
      expect(validator.valid?).to be(false)
    end
  end

  private

  def validator_for_modified_json
    json = PlanSnapshotValues.mock_extension_json.deep_dup
    yield(json)
    described_class.new(json)
  end

  def template_json(json)
    json['template']
  end

  def questions_json(json)
    template_json(json)['phases'].flat_map do |phase|
      phase['sections'].flat_map do |section|
        section['questions']
      end
    end
  end

  def blank_all_answers(json)
    questions_json(json).each do |question|
      question['answer'] = { 'text' => '' }
    end
  end

  def remove_all_answers(json)
    questions_json(json).each do |question|
      question.delete('answer')
    end
  end

  def add_unanswered_question(json)
    question = questions_json(json).first.deep_dup
    question['id'] = 999
    question['answer'] = { 'text' => '' }

    template_json(json)
      .dig('phases', 0, 'sections', 0, 'questions')
      .append(question)
  end
end
