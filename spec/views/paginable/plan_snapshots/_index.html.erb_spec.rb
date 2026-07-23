# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'paginable/plan_snapshots/_index.html.erb', type: :view do
  let(:plan) { create(:plan, :snapshot_ready) }
  let(:snapshot) { create(:plan_snapshot, plan: plan) }

  before do
    view.extend(Paginable)
    view.instance_variable_set(:@args, {
                                 controller: 'paginable/plan_snapshots',
                                 action: 'index',
                                 page: 1,
                                 sort_field: 'plan_snapshots.version',
                                 sort_direction: 'desc'
                               })
    view.instance_variable_set(:@paginable_options, { remote: true })
    view.instance_variable_set(:@paginable_path_params, { plan_id: plan.id })

    render partial: 'paginable/plan_snapshots/index',
           locals: {
             plan: plan,
             scope: PlanSnapshot.where(id: snapshot.id)
           }
  end

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

  it 'renders the snapshot row and view link' do
    expect(rendered).to include(
      snapshot.dmp_id.identifier.to_s,
      snapshot.dmp_id.type.to_s,
      snapshot.version.to_s,
      snapshot.created_at.to_date.to_s,
      snapshot.visibility_label,
      'View'
    )
  end
end
