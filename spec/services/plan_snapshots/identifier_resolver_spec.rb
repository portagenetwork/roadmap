# frozen_string_literal: true

require 'rails_helper'

RSpec.describe PlanSnapshots::IdentifierResolver do
  describe '.call' do
    let(:snapshot) { create(:plan_snapshot) }
    let(:plan) { snapshot.plan }

    it 'returns the version URL and url type' do
      resolved = described_class.call(plan: plan, snapshot: snapshot)

      expect(resolved.identifier).to eq(Rails.application.routes.url_helpers.plan_snapshot_url(plan, snapshot))
      expect(resolved.type).to eq('url')
    end
  end
end
