# frozen_string_literal: true

require 'rails_helper'
require_relative '../../support/mocks/plan_snapshot_values'

RSpec.describe PlanSnapshots::RdaJsonValidator do
  subject(:validator) { described_class.new(payload) }

  let(:payload) { PlanSnapshotValues.mock_rda_json }

  describe '#valid?' do
    it 'returns true when rda_json has required dmp fields' do
      expect(validator.valid?).to be(true)
    end

    it 'returns false when rda_json is missing dmp.title' do
      expect(validator_with_modified_json { |json| json['dmp'].delete('title') }.valid?).to be(false)
    end

    it 'returns false when rda_json is missing dmp.dmp_id.identifier' do
      expect(validator_with_modified_json { |json| json['dmp']['dmp_id'].delete('identifier') }.valid?).to be(false)
    end

    it 'returns false when rda_json is missing dmp.dmp_id.type' do
      expect(validator_with_modified_json { |json| json['dmp']['dmp_id'].delete('type') }.valid?).to be(false)
    end

    it 'returns false when rda_json is missing dmp.project.start' do
      expect(validator_with_modified_json { |json| json['dmp']['project'].first.delete('start') }.valid?).to be(false)
    end

    it 'returns false when rda_json is missing dmp.project.end' do
      expect(validator_with_modified_json { |json| json['dmp']['project'].first.delete('end') }.valid?).to be(false)
    end

    it 'returns false when dmp or dmp_id is missing' do
      expect(described_class.new({}).valid?).to be(false)
    end
  end

  def validator_with_modified_json
    json = PlanSnapshotValues.mock_rda_json.deep_dup
    yield(json)
    described_class.new(json)
  end
end
