# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Api::BaseApiController, type: :controller do
  controller(Api::BaseApiController) do
    before_action -> { doorkeeper_authorize! :v2_read }

    def index
      head :ok
    end
  end

  describe 'scope enforcement' do
    let(:user) { create(:user) }
    let(:oauth_app) { create(:oauth_application, scopes: 'v2_read') }

    before do
      routes.draw do
        get 'index' => 'api/base_api#index'
      end
    end

    it 'returns 401 Unauthorized when the token is missing the required API scope' do
      access_token = create(:oauth_access_token,
                            application: oauth_app,
                            resource_owner_id: user.id,
                            scopes: 'common_madmp_read')

      request.env['HTTP_AUTHORIZATION'] = "Bearer #{access_token.token}"

      get :index

      expect(response).to have_http_status(:unauthorized)
    end
  end
end
