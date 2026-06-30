# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'plan_snapshots/index.html.erb', type: :view do
  let(:plan) { create(:plan, title: 'Test Plan') }

  before do
    # Required because this view renders `layout: 'plans/navigation'`, which calls `current_user`.
    user = create(:user)
    view.singleton_class.define_method(:current_user) { user }

    render locals: {
      plan: plan,
      snapshots: [],
      snapshot_creation_enabled: true
    }
  end

  it 'renders the page title and heading' do
    expect(view.content_for(:title)).to eq('Test Plan - Versions')
    expect(rendered).to include('Test Plan')
  end
end
