# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Api::V2::Serialization::PlanSnapshots::ExtensionSerializer do
  describe '.call' do
    let(:plan) { create(:plan, :creator) }

    it 'returns a hash' do
      result = described_class.call(plan: plan)
      expect(result).to be_a(Hash)
    end

    it 'returns only extension payload (not full dmp wrapper)' do
      result = described_class.call(plan: plan)
      expect(result).not_to have_key(:dmp)
      expect(result).to have_key('extension')
    end

    it 'does not include RDA root fields' do
      result = described_class.call(plan: plan)
      expect(result).not_to have_key('dmp_id')
    end

    it 'requires a plan keyword argument' do
      expect { described_class.call }.to raise_error(ArgumentError)
    end

    context 'when the plan has answers' do
      let(:question) { create(:question, section: create(:section, template: plan.template)) }
      let!(:answer) { create(:answer, plan: plan, question: question, text: 'Test answer') }

      it 'renders the complete_plan section with Q&A' do
        result = described_class.call(plan: plan)
        extension = result['extension'].first
        expect(extension['complete_plan']).to be_an(Array)
        expect(extension['complete_plan'].first['question_id']).to eq(question.id)
        expect(extension['complete_plan'].first['answer']).to eq('Test answer')
      end
    end

    context 'when the plan has no answers' do
      it 'does not render the complete_plan section' do
        result = described_class.call(plan: plan)
        extension = result['extension'].first
        expect(extension['complete_plan']).to be_nil
      end
    end
  end
end
