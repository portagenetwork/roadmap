# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'api/common_madmp/dmps/_dmp', type: :view do
  let(:plan) { create(:plan) }

  it 'renders the plan ID and DMP data' do
    render partial: 'api/common_madmp/dmps/dmp', locals: { plan: plan }

    json = JSON.parse(rendered)

    expect(json.keys).to contain_exactly('id', 'dmp')
    expect(json['id']).to eq(plan.id)
    expect(json['dmp']).to be_a(Hash)
  end
end
