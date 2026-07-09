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
      expect(
        validator_with_modified_json { |json| json['extension'].first.delete('complete_plan') }.valid?
      ).to be(false)
    end

    it 'returns false when complete_plan item is missing required fields' do
      expect(validator_with_modified_json do |json|
               json['extension'].first['complete_plan'].first.delete('question_id')
             end.valid?).to be(false)
    end
  end

  def validator_with_modified_json
    json = PlanSnapshotValues.mock_extension_json.deep_dup
    yield(json)
    described_class.new(json)
  end
end
