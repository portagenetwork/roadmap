# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'plan_snapshots/index.html.erb', type: :view do
  let(:plan) { create(:plan, :snapshot_ready, title: 'Test Plan') }
  let(:snapshots) { [] }
  let(:can_create_snapshot) { false }
  let(:snapshot_blockers) { [] }

  before do
    # Required because this view renders `plans/navigation`, which calls `current_user`.
    user = create(:user)
    view.singleton_class.define_method(:current_user) { user }
    view.stubs(:paginable_renderise).returns('')

    render locals: {
      plan: plan,
      snapshots: snapshots,
      can_create_snapshot: can_create_snapshot,
      snapshot_blockers: snapshot_blockers
    }
  end

  it 'renders the page title and heading' do
    expect(view.content_for(:title)).to eq('Test Plan - Versions')
    expect(rendered).to include('Test Plan')
  end

  it 'renders the empty state' do
    expect(rendered).to include('No versions of this DMP have been published.')
  end

  context 'when snapshots exist' do
    let(:snapshot) { create(:plan_snapshot, plan: plan) }
    let(:snapshots) { PlanSnapshot.where(id: snapshot.id) }

    it 'renders versions guidance text and not the empty state' do
      expect(rendered).to include('This is a list of your versioned DMPs with any associated identifiers.')
      expect(rendered).not_to include('No versions of this DMP have been published.')
    end
  end

  context 'when the user can create snapshots' do
    let(:can_create_snapshot) { true }

    it 'renders the create snapshot form' do
      expect(rendered).to include('Create a version of this DMP')
    end
  end
end
