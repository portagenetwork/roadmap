# frozen_string_literal: true

require 'rails_helper'

describe FeatureFlagHelper do
  include FeatureFlagHelper

  describe '.enabled?' do
    it 'returns the configured sandbox flag' do
      Rails.configuration.x.application.stubs(:on_sandbox).returns(true)

      expect(described_class.enabled?(:on_sandbox)).to be(true)
    end

    it 'returns false for unknown features' do
      expect(described_class.enabled?(:unknown)).to be(false)
    end
  end
end
