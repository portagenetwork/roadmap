# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'GET /.well-known/api-catalog' do
  it 'returns a linkset' do
    get '/.well-known/api-catalog'
    expect(response).to have_http_status(:ok)
    expect(response.headers['Content-Type']).to include('application/linkset+json')

    body = JSON.parse(response.body)
    hrefs = body['linkset'].first['item'].pluck('href')
    expect(hrefs).to include("#{Rails.application.secrets.omniauth_full_host}/api/madmp")
    expect(hrefs).to include("#{Rails.application.secrets.omniauth_full_host}/api/v2")

    common_madmp_service_docs = body['linkset'][1]['service-doc'].map { |entry| entry['href'] }
    expect(common_madmp_service_docs).to include('https://github.com/portagenetwork/roadmap/wiki/OAuth-2.0-Authentication')

    v2_service_docs = body['linkset'][2]['service-doc'].map { |entry| entry['href'] }
    expect(v2_service_docs).to include('https://github.com/portagenetwork/roadmap/wiki/API-v2-Documentation')
    expect(v2_service_docs).to include('https://github.com/portagenetwork/roadmap/wiki/OAuth-2.0-Authentication')
  end

  it 'supports HEAD with a Link header' do
    head '/.well-known/api-catalog'
    expect(response).to have_http_status(:ok)
    expect(response.headers['Link']).to include('rel="api-catalog"')
  end
end
