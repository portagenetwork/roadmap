# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'plan_snapshots/_index.html.erb', type: :view do
  let(:plan) { create(:plan) }
  let(:snapshots) { [] }
  let(:snapshot_creation_enabled) { true }

  before do
    render partial: 'plan_snapshots/index',
           locals: {
             plan: plan,
             snapshots: snapshots,
             snapshot_creation_enabled: snapshot_creation_enabled
           }
  end

  context 'when snapshots exist' do
    let(:snapshot) { create(:plan_snapshot, plan: plan) }
    let(:snapshots) { [snapshot] }

    it 'renders table headers' do
      expect(rendered).to include(
        'Identifier',
        'Type',
        'Version',
        'Release date',
        'Visibility',
        'Actions'
      )
    end

    it 'renders the snapshot row' do
      expect(rendered).to include(
        snapshot.dmp_identifier.to_s,
        snapshot.dmp_identifier_type.to_s,
        snapshot.version.to_s,
        snapshot.created_at.to_date.to_s,
        snapshot.visibility_label
      )
    end

    it 'renders the view link' do
      expect(rendered).to include('View')
    end
  end

  context 'when snapshots are empty' do
    it 'renders the empty state message' do
      expect(rendered).to include(
        'No versions of this DMP have been published.'
      )
    end

    it 'does not render the table' do
      expect(rendered).not_to include('<table')
    end
  end

  context 'when snapshot creation is enabled' do
    it 'renders the create snapshot form' do
      expect(rendered).to include(
        'Create a version of this DMP',
        'plan_snapshot[visibility]',
        'privately_visible'
      )
    end
  end

  context 'when snapshot creation is disabled' do
    let(:snapshot_creation_enabled) { false }

    it 'does not render the create snapshot form' do
      expect(rendered).not_to include('Create a version of this DMP')
      expect(rendered).not_to include('plan_snapshot[visibility]')
      expect(rendered).not_to include('privately_visible')
      expect(rendered).not_to include(%(<form))
    end
  end
end
