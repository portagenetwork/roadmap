# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'shared/export/_plan_snapshot_coversheet.erb', type: :view do
  let(:snapshot) { create(:plan_snapshot) }

  before do
    assign(:snapshot, snapshot)
    assign(:investigators, snapshot.contributors.with_role(:investigation))
    assign(:data_curators, snapshot.contributors.with_role(:data_curation))
    assign(:project_administrators, snapshot.contributors.with_role(:project_administration))
    assign(:other_contributors, snapshot.contributors.with_role(:other))
  end

  subject(:render_partial) { render partial: 'shared/export/plan_snapshot_coversheet' }

  it 'renders snapshot title and attribution' do
    render_partial

    expect(rendered).to include(snapshot.title)
    expect(rendered).to include('A Data Management Plan created using')
    expect(rendered).to include('Creator:')
    expect(rendered).to include(snapshot.contact.name)
  end

  it 'falls back to the contact email when the contact name is blank' do
    rda_json = snapshot.rda_json.deep_dup
    rda_json['dmp']['contact']['name'] = ''
    snapshot.update_column(:rda_json, rda_json)
    snapshot.remove_instance_variable(:@rda_json_reader)

    render_partial

    expect(rendered).to include('Creator:')
    expect(rendered).to include(snapshot.contact.mbox)
  end

  it 'renders contributor role sections' do
    render_partial

    expect(rendered).to include('Principal Investigator:')
    expect(rendered).to include('Data Manager:')
    expect(rendered).to include('Project Administrator:')
    expect(rendered).to include('Contributor:')
  end

  it 'renders metadata from snapshot JSON wrappers' do
    render_partial

    expect(rendered).to include(snapshot.contact.affiliation.name)
    expect(rendered).to include(snapshot.project.funding.name)
    expect(rendered).to include(snapshot.template.title)
    expect(rendered).to include(snapshot.dmp_id.identifier)
    expect(rendered).to include(snapshot.project.funding.grant_id.identifier)
  end

  it 'renders ORCID values for investigators when present' do
    render_partial

    identifier = snapshot.contributors
                         .find { |c| c.contributor_id&.identifier.present? }
                         &.contributor_id
                         &.identifier
    expect(rendered).to include('ORCID iD:')
    expect(rendered).to include(identifier)
  end
end
