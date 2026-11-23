# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Health check', type: :request do
  it 'returns ok when the application is running' do
    expect(rails_health_check_path).to eq('/up')
    get '/up'

    expect(response).to have_http_status(:ok)
    expect(response.media_type).to eq('text/html')
    expect(response.body).to include('background-color: green')
  end
end
