# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Api::V1::PlansController, type: :request do
  include ApiHelper

  context 'ApiClient' do
    before(:each) do
      mock_authorization_for_api_client

      # Org model requires a language so make sure the default is set
      create(:language, abbreviation: 'v1-plans', default_language: true) unless Language.default.present?
    end

    describe 'GET /api/v1/plan/:id - show' do
      it 'returns the plan' do
        client = ApiClient.first
        client.update(org: create(:org)) if client.org.blank?
        mock_authorization_for_api_client

        plan = create(:plan, org: client.org)
        get api_v1_plan_path(plan)
        expect(response.code).to eql('200')
        expect(response).to render_template('api/v1/plans/index')
        expect(assigns(:items).length).to eql(1)
      end
      it 'returns a 404 if the ApiClient does not have access to the plan' do
        client = ApiClient.first
        client.update(org: create(:org)) if client.org.blank?
        mock_authorization_for_api_client

        other_org = create(:org)
        plan = create(:plan, org: other_org)
        get api_v1_plan_path(plan)
        expect(response.code).to eql('404')
        expect(response).to render_template('api/v1/error')
      end
      it 'returns a 404 if not found' do
        get api_v1_plan_path(9999)
        expect(response.code).to eql('404')
        expect(response).to render_template('api/v1/error')
      end
    end

    describe 'POST /api/v1/plans - create' do
      include Webmocks
      include Mocks::ApiJsonSamples

      before(:each) do
        stub_ror_service
        mock_identifier_schemes
        create(:template, :publicly_visible, is_default: true, published: true)
      end

      context 'minimal JSON' do
        before(:each) do
          @json = JSON.parse(minimal_create_json).with_indifferent_access
        end

        it 'returns a 400 if the incoming JSON is invalid' do
          post api_v1_plans_path, params: Faker::Lorem.word
          expect(response.code).to eql('400')
          expect(response).to render_template('api/v1/error')
        end
        it 'returns a 201 if the incoming JSON is valid' do
          post api_v1_plans_path, params: @json.to_json
          expect(response.code).to eql('201')
          expect(response).to render_template('api/v1/plans/index')
        end
      end

      context 'complete JSON' do
        before(:each) do
          @json = JSON.parse(complete_create_json).with_indifferent_access
        end

        it 'returns a 201 if the incoming JSON is valid' do
          post api_v1_plans_path, params: @json.to_json
          expect(response.code).to eql('201')
          expect(response).to render_template('api/v1/plans/index')
        end
      end
    end
  end

  context 'User' do
    describe 'GET /api/v1/plan/:id - show' do
      it 'returns the plan if the user owns it' do
        plan = create(:plan, :creator, :organisationally_visible)
        mock_authorization_for_user(user: plan.owner)
        get api_v1_plan_path(plan)
        expect(response.code).to eql('200')
        expect(response).to render_template('api/v1/plans/index')
        expect(assigns(:items).length).to eql(1)
      end
      it 'returns the plan if its :organisationally_visible and user.org matches plan.org' do
        owner = create(:user, org: create(:org))
        plan = create(:plan, :creator, :organisationally_visible,
                      org: owner.org, creator: owner)
        other_user = create(:user, org: plan.org)
        mock_authorization_for_user(user: other_user)
        get api_v1_plan_path(plan)
        expect(response.code).to eql('200')
        expect(response).to render_template('api/v1/plans/index')
        expect(assigns(:items).length).to eql(1)
      end
      it 'returns the plan if the user is an Org Admin and it belongs to their Org' do
        owner = create(:user, org: create(:org))
        plan = create(:plan, :creator, org: owner.org, creator: owner)
        org_admin = create(:user, :org_admin, org: plan.org)
        mock_authorization_for_user(user: org_admin)
        get api_v1_plan_path(plan)
        expect(response.code).to eql('200')
        expect(response).to render_template('api/v1/plans/index')
        expect(assigns(:items).length).to eql(1)
      end
      it 'returns a 404 if not found' do
        mock_authorization_for_user
        get api_v1_plan_path(9999)
        expect(response.code).to eql('404')
        expect(response).to render_template('api/v1/error')
      end
      it 'returns a 404 if the user does not have access' do
        mock_authorization_for_user
        org2 = create(:org)
        plan = create(:plan, :creator, :organisationally_visible, org: org2)
        get api_v1_plan_path(plan)
        expect(response.code).to eql('404')
        expect(response).to render_template('api/v1/error')
      end
    end
  end
end
