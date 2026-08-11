# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Api::V2::Serialization::PlanSnapshots::RdaSerializer do
  describe '.call' do
    let(:plan) { create(:plan, :creator) }

    it 'returns a hash with dmp key' do
      result = described_class.call(plan: plan)
      expect(result).to be_a(Hash)
      expect(result).to have_key(:dmp)
    end

    it 'returns a dmp hash containing parsed JSON' do
      result = described_class.call(plan: plan)
      expect(result[:dmp]).to be_a(Hash)
    end

    it 'excludes extension payload content' do
      result = described_class.call(plan: plan)
      expect(result[:dmp]).not_to have_key('extension')
    end

    it 'requires a plan keyword argument' do
      expect { described_class.call }.to raise_error(ArgumentError)
    end
  end
end
