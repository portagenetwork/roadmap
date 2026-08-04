# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Api::V2::Serialization::PlanSnapshots::ExtensionSerializer do
  describe '.call' do
    let(:plan) { create(:plan, :creator) }

    it 'returns a hash' do
      result = described_class.call(plan: plan)
      expect(result).to be_a(Hash)
    end

    it 'returns a template payload keyed at the top level' do
      result = described_class.call(plan: plan)
      expect(result).to have_key('template')
    end

    it 'does not include the RDA dmp wrapper' do
      result = described_class.call(plan: plan)
      expect(result).not_to have_key('dmp')
      expect(result).not_to have_key('dmp_id')
    end

    it 'requires a plan keyword argument' do
      expect { described_class.call }.to raise_error(ArgumentError)
    end

    it "renders the plan's actual template id through the full pipeline" do
      result = described_class.call(plan: plan)
      expect(result['template']['id']).to eq(plan.template.id)
    end
  end
end
