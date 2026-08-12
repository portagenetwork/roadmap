# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'plan_snapshots/_create_snapshot_form.html.erb', type: :view do
  let(:plan) { create(:plan) }
  let(:snapshot_blockers) { [] }

  before do
    render partial: 'plan_snapshots/create_snapshot_form',
           locals: {
             plan: plan,
             snapshot_blockers: snapshot_blockers
           }
  end

  it 'renders the snapshot creation form' do
    expect(rendered).to include('Create a version of this DMP')
    expect(rendered).to include('plan_snapshot[visibility]')
    expect(rendered).to include('privately_visible')
  end

  context 'when there are no blockers' do
    it 'does not render the warning message' do
      expect(rendered).not_to include(
        'Unable to create a version of this DMP. Please address the following:'
      )
    end

    it 'renders an enabled submit button' do
      expect(rendered).not_to match(/disabled/)
    end
  end

  context 'when blockers exist' do
    let(:snapshot_blockers) do
      [
        'A project start date must be included.',
        'A project end date must be included.'
      ]
    end

    it 'renders the warning message' do
      expect(rendered).to include(
        'Unable to create a version of this DMP. Please address the following:'
      )
    end

    it 'renders each blocker' do
      snapshot_blockers.each do |blocker|
        expect(rendered).to include(blocker)
      end
    end

    it 'renders a disabled submit button' do
      expect(rendered).to match(/disabled/)
    end
  end
end
