# frozen_string_literal: true

require 'rails_helper'

RSpec.describe PlanSnapshots::IdentifierResolver do
  describe '.call' do
    let(:snapshot) { create(:plan_snapshot) }

    it 'returns the version URL and url type' do
      resolved = described_class.call(snapshot: snapshot)
      resolved_path = URI.parse(resolved.identifier).path

      expect(resolved.identifier).to eq(Rails.application.routes.url_helpers.plan_snapshot_url(snapshot.plan, snapshot))
      expect(resolved_path).to eq("/plans/#{snapshot.plan_id}/versions/#{snapshot.version}")
      expect(resolved.type).to eq('url')
    end
  end
end
