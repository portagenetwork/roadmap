# frozen_string_literal: true

require 'rails_helper'
require_relative '../../support/mocks/plan_snapshot_values'

RSpec.describe PlanSnapshots::ExtensionJsonValidator do
  subject(:validator) { described_class.new(payload) }

  let(:payload) { PlanSnapshotValues.mock_extension_json }

  describe '#valid?' do
    it 'returns true when extension_json has required template and complete_plan fields' do
      expect(validator.valid?).to be(true)
    end

    it 'returns false when template.id is missing' do
      expect(validator_with_modified_json do |json|
               json['extension'].first['dmproadmap']['template'].delete('id')
             end.valid?).to be(false)
    end

    it 'returns false when template.title is missing' do
      expect(validator_with_modified_json do |json|
               json['extension'].first['dmproadmap']['template'].delete('title')
             end.valid?).to be(false)
    end

    it 'returns false when complete_plan is missing' do
      expect(validator_with_modified_json do |json|
               json['extension'].first.delete('complete_plan')
             end.valid?).to be(false)
    end

    it 'returns false when complete_plan is empty' do
      expect(validator_with_modified_json do |json|
               json['extension'].first['complete_plan'] = []
             end.valid?).to be(false)
    end

    it 'returns false when a complete_plan item is missing question_id' do
      expect(validator_with_modified_json do |json|
               json['extension'].first['complete_plan'].first.delete('question_id')
             end.valid?).to be(false)
    end

    %w[answer title section question].each do |field|
      it "returns false when a complete_plan item is missing #{field}" do
        expect(
          validator_with_modified_json do |json|
            json['extension'].first['complete_plan'].first.delete(field)
          end.valid?
        ).to be(false)
      end
    end
  end

  context 'when extension_json is nil' do
    let(:payload) { nil }

    it 'returns false' do
      expect(validator.valid?).to be(false)
    end
  end

  def validator_with_modified_json
    json = PlanSnapshotValues.mock_extension_json.deep_dup
    yield(json)
    described_class.new(json)
  end
end
