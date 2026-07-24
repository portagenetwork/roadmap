# frozen_string_literal: true

require 'rails_helper'
require_relative '../../support/mocks/plan_snapshot_values'

RSpec.describe PlanSnapshots::ExtensionJson do
  let(:mock_extension) { PlanSnapshotValues.mock_extension_json }
  let(:reader) { described_class.new(extension_json: mock_extension) }
  let(:extension_json) { mock_extension['extension'].first }
  let(:dmproadmap_json) { extension_json['dmproadmap'] }

  describe '#template' do
    let(:template_json) { dmproadmap_json['template'] }
    describe '#id' do
      it 'returns template.id' do
        expect(reader.template.id).to eq(template_json['id'])
      end
    end

    describe '#title' do
      it 'returns template.title' do
        expect(reader.template.title).to eq(template_json['title'])
      end
    end
  end

  describe '#complete_plan' do
    let(:complete_plan_json) { extension_json['complete_plan'] }
    it 'returns complete plan items' do
      expect(reader.complete_plan.length).to eq(1)
    end

    describe 'first item' do
      let(:item) { reader.complete_plan.first }
      let(:item_json) { complete_plan_json.first }

      it 'returns title' do
        expect(item.title).to eq(item_json['title'])
      end

      it 'returns answer' do
        expect(item.answer).to eq(item_json['answer'])
      end

      it 'returns section' do
        expect(item.section).to eq(item_json['section'])
      end

      it 'returns question' do
        expect(item.question).to eq(item_json['question'])
      end

      it 'returns question_id' do
        expect(item.question_id).to eq(item_json['question_id'])
      end
    end

    context 'when extension.complete_plan is an empty array' do
      let(:mock_extension) do
        json = PlanSnapshotValues.mock_extension_json
        json['extension'].first['complete_plan'] = []
        json
      end

      it 'returns an empty array' do
        expect(reader.complete_plan).to eq([])
      end
    end

    context 'when extension.complete_plan is absent' do
      let(:mock_extension) do
        json = PlanSnapshotValues.mock_extension_json
        json['extension'].first.delete('complete_plan')
        json
      end

      it 'returns an empty array' do
        expect(reader.complete_plan).to eq([])
      end
    end
  end

  context 'when extension_json is missing expected keys' do
    let(:reader) { described_class.new(extension_json: {}) }

    it 'returns nil for scalar accessors' do
      expect(reader.template.id).to be_nil
      expect(reader.template.title).to be_nil
    end

    it 'returns an empty array for complete_plan' do
      expect(reader.complete_plan).to eq([])
    end
  end

  context 'when extension_json is nil' do
    let(:reader) { described_class.new(extension_json: nil) }

    it 'does not raise and returns nil/empty defaults' do
      expect(reader.template.id).to be_nil
      expect(reader.template.title).to be_nil
      expect(reader.complete_plan).to eq([])
    end
  end
end
