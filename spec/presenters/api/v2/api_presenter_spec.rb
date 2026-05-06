# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Api::V2::ApiPresenter do
  describe '.boolean_to_yes_no_unknown(value:)' do
    it 'returns yes for true' do
      expect(described_class.boolean_to_yes_no_unknown(value: true)).to eql('yes')
    end

    it 'returns no for false' do
      expect(described_class.boolean_to_yes_no_unknown(value: false)).to eql('no')
    end

    it 'returns unknown for nil' do
      expect(described_class.boolean_to_yes_no_unknown(value: nil)).to eql('unknown')
    end
  end
end
