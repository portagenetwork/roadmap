# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Api::CommonMadmp::PlansController do
  include ApiHelper
  include Api::CommonMadmp::Helpers
  include Mocks::ApiV2JsonSamples
  include Webmocks
  include IdentifierHelper

  context 'OAuth (authorization_code grant type) — on behalf of a user' do
    before do
      @user = create(:user)
      @client = create(:oauth_application)
      token = mock_authorization_code_token(oauth_application: @client, user: @user).plaintext_token

      @headers = {
        Accept: 'application/json',
        'Content-Type': 'application/json',
        Authorization: "Bearer #{token}"
      }
    end

    def fetch_plans_json_response
      get(dmps_path, headers: @headers)
      expect(response).to render_template('api/common_madmp/_standard_response')
      expect(response).to render_template('api/common_madmp/dmps/index')
      JSON.parse(response.body).with_indifferent_access
    end

    def fetch_plan_json_response(plan)
      get(dmp_path(plan), headers: @headers)
      expect(response).to render_template('api/common_madmp/dmps/show')
      JSON.parse(response.body).with_indifferent_access
    end

    def expect_invalid_token_response
      headers = @headers.merge('Authorization' => "Bearer #{SecureRandom.uuid}")
      yield(headers)

      expect_authentication_required_error
    end

    def expect_insufficient_scope_response
      read_only_client = create(:oauth_application, scopes: 'read')
      token = mock_authorization_code_token(oauth_application: read_only_client, user: @user).plaintext_token
      headers = @headers.merge('Authorization' => "Bearer #{token}")
      yield(headers)

      expect(response.code).to eql('403')
    end

    describe 'Content negotiation (Accept header)' do
      let!(:plan) do
        plan = create(:plan, org: @user.org)
        plan.add_user!(@user.id, :creator)
        plan
      end

      let(:vendor_type) { 'application/vnd.org.rd-alliance.dmp-common.v1.2+json' }

      context 'when no Accept header is included' do
        it 'defaults to the stock JSON response' do
          get(dmps_path, headers: @headers.except(:Accept))

          expect(response).to have_http_status(:ok)
          expect(response.headers['Content-Type']).to start_with('application/json')
          expect(response).to render_template('api/common_madmp/dmps/index')
        end

        it 'also negotiates correctly on the show action' do
          get(dmps_path(plan), headers: @headers.except(:Accept))

          expect(response).to have_http_status(:ok)
          expect(response.headers['Content-Type']).to start_with('application/json')
        end
      end

      context 'when Accept: */* is included' do
        it 'defaults to the stock JSON response' do
          get(dmps_path, headers: @headers.merge(Accept: '*/*'))

          expect(response).to have_http_status(:ok)
          expect(response.headers['Content-Type']).to start_with('application/json')
        end
      end

      context 'when Accept: application/* is included' do
        it 'defaults to the stock JSON response' do
          get(dmps_path, headers: @headers.merge(Accept: 'application/*'))

          expect(response).to have_http_status(:ok)
          expect(response.headers['Content-Type']).to start_with('application/json')
        end
      end

      context 'when unqualified application/json is requested' do
        it 'returns the stock JSON response' do
          get(dmps_path, headers: @headers.merge(Accept: 'application/json'))

          expect(response).to have_http_status(:ok)
          expect(response.headers['Content-Type']).to start_with('application/json')
        end
      end

      context 'when the RDA DMP v1.2 MIME type is requested' do
        it 'returns the RDA DMP v1.2 content type' do
          get(dmps_path, headers: @headers.merge(Accept: vendor_type))

          expect(response).to have_http_status(:ok)
          expect(response.headers['Content-Type']).to start_with(vendor_type)
          expect(response).to render_template('api/common_madmp/dmps/index')
        end

        it 'also negotiates correctly on the show action' do
          get(dmps_path(plan), headers: @headers.merge(Accept: vendor_type))

          expect(response).to have_http_status(:ok)
          expect(response.headers['Content-Type']).to start_with(vendor_type)
          expect(response).to render_template('api/common_madmp/dmps/index')
        end
      end

      context 'when multiple acceptable MIME types are requested' do
        it 'selects the type with the highest client preference' do
          accept = "application/json;q=0.5, #{vendor_type};q=1.0"
          get(dmps_path, headers: @headers.merge(Accept: accept))

          expect(response).to have_http_status(:ok)
          expect(response.headers['Content-Type']).to start_with(vendor_type)
        end

        it 'selects JSON when it has the highest client preference' do
          accept = "application/json;q=1.0, #{vendor_type};q=0.5"
          get(dmps_path, headers: @headers.merge(Accept: accept))

          expect(response).to have_http_status(:ok)
          expect(response.headers['Content-Type']).to start_with('application/json')
        end

        it 'preserves header order when preferences are tied' do
          accept = "#{vendor_type};q=0.8, application/json;q=0.8"
          get(dmps_path, headers: @headers.merge(Accept: accept))

          expect(response).to have_http_status(:ok)
          expect(response.headers['Content-Type']).to start_with(vendor_type)
        end
      end

      context 'when a type is explicitly excluded with q=0' do
        it 'does not select the excluded type, even with no other acceptable type' do
          accept = 'application/json;q=0'
          get(dmps_path, headers: @headers.merge(Accept: accept))

          expect(response).to have_http_status(:not_acceptable)
          expect(response).to render_template('api/common_madmp/error')
        end

        it 'falls back to the remaining acceptable type' do
          accept = "application/json;q=0, #{vendor_type};q=0.5"
          get(dmps_path, headers: @headers.merge(Accept: accept))

          expect(response).to have_http_status(:ok)
          expect(response.headers['Content-Type']).to start_with(vendor_type)
        end
      end

      context 'when an unsupported MIME type is requested' do
        let(:bogus_type) { 'application/vnd.org.rd-alliance.dmp-common.v1.999+json' }

        it 'returns 406 Not Acceptable' do
          get(dmps_path, headers: @headers.merge(Accept: bogus_type))

          expect(response).to have_http_status(:not_acceptable)
          expect(response).to render_template('api/common_madmp/error')
        end

        it 'does not echo the unsupported type back as Content-Type' do
          get(dmps_path, headers: @headers.merge(Accept: bogus_type))

          expect(response.headers['Content-Type']).not_to start_with(bogus_type)
        end

        it 'returns the expected error_code in the body' do
          get(dmps_path, headers: @headers.merge(Accept: bogus_type))

          json = JSON.parse(response.body)
          expect(json['error_code']).to eq('not_acceptable')
          expect(json['error_message']).to be_present
        end

        it 'also rejects the show action' do
          get(dmps_path(plan), headers: @headers.merge(Accept: bogus_type))

          expect(response).to have_http_status(:not_acceptable)
          expect(response).to render_template('api/common_madmp/error')
        end
      end

      context 'when an unsupported type is requested alongside a supported type' do
        it 'selects the supported RDA representation' do
          accept = "application/xml, #{vendor_type}"
          get(dmps_path, headers: @headers.merge(Accept: accept))

          expect(response).to have_http_status(:ok)
          expect(response.headers['Content-Type']).to start_with(vendor_type)
        end
      end
    end

    describe 'GET /dmps (index)' do
      context 'an invalid API token is included' do
        it 'returns a 401 and the expected Oauth 2.0 headers' do
          expect_invalid_token_response { |headers| get(dmps_path, headers: headers) }
        end
      end

      context 'a valid API token is included' do
        let(:json) { fetch_plans_json_response }
        it 'returns a 200 and the expected response body' do
          # Items array is empty
          expect(json[:items]).to eq([])

          # total_count reflects that nothing is returned
          expect(json[:total_count]).to eq(0)

          # Status code and message are correct
          expect(json[:code]).to eq(200)
          expect(json[:message]).to eq('OK')

          # Application and source are present and sensible
          expect(json[:application]).to eq(ApplicationService.application_name)
          expect(json[:source]).to eq('GET /dmps')

          # Time is present and parseable
          expect { Time.iso8601(json[:time]) }.not_to raise_error

          # Caller is included
          expect(json[:caller]).to eq(@client.name)
        end

        it 'returns an empty array if no plans are available' do
          # Items array is empty
          expect(json[:items]).to eq([])

          # total_count reflects that nothing is returned
          expect(json[:total_count]).to eq(0)
        end

        it 'returns the expected plans' do
          # See `app/policies/api/v2/plans_policy.rb for plans included/excluded via `GET api/v2/plans`

          # Create the included plans
          included_plans = [create(:plan, org: @user.org), create(:plan)]
          included_plans[0].add_user!(@user.id, :creator)
          # Add multiple roles for testing (ensure duplicate plans will not returned)
          included_plans[1].add_user!(@user.id, :editor)
          included_plans[1].add_user!(@user.id, :commenter)

          # Created the excluded plans
          create(:plan, :creator, org: @user.org)
          inactive_plan = create(:plan, :creator)
          inactive_plan.add_user!(@user.id, :editor)
          Role.where(plan_id: inactive_plan.id, user_id: @user.id).update(active: false)

          expect(json[:items].length).to be(included_plans.length)
          expect(json[:items].map { |item| item[:id] }).to contain_exactly(*included_plans.map(&:id))
        end

        it 'allows for paging' do
          original_page_size = Rails.configuration.x.application.api_max_page_size
          Rails.configuration.x.application.api_max_page_size = 10

          create_list(:plan, 11, :publicly_visible) do |plan|
            plan.add_user!(@user.id, :commenter)
          end
          json = fetch_plans_json_response

          test_paging(json: json, headers: @headers)

          Rails.configuration.x.application.api_max_page_size = original_page_size
        end

        it 'generates correct offset and count pagination links' do
          original_page_size = Rails.configuration.x.application.api_max_page_size
          Rails.configuration.x.application.api_max_page_size = 10

          create_list(:plan, 25, :publicly_visible) do |plan|
            plan.add_user!(@user.id, :commenter)
          end

          get(dmps_path, params: { offset: '10', count: '10' }, headers: @headers)
          expect(response).to have_http_status(:ok)

          json = JSON.parse(response.body).with_indifferent_access
          expect(json[:next]).to include('offset=20')
          expect(json[:next]).to include('count=10')
          expect(json[:prev]).to include('offset=0')
          expect(json[:prev]).to include('count=10')

          Rails.configuration.x.application.api_max_page_size = original_page_size
        end
      end
    end

    describe 'GET /dmps/:id (show)' do
      context 'an invalid API token is included' do
        it 'returns a 401 and the expected Oauth 2.0 headers' do
          plan = create(:plan)
          expect_invalid_token_response { |headers| get(dmp_path(plan), headers: headers) }
        end
      end

      context 'a valid API token is included' do
        shared_examples 'returns a 404 Plan not found for show' do
          it do
            expect(response.code).to eql('404')
            expect(response).to render_template('api/common_madmp/error')

            json = JSON.parse(response.body).with_indifferent_access

            expect(json[:error_code]).to eq('dmp_not_found')
            expect(json[:error_message]).to eq('Plan not found')
          end
        end

        it 'returns a 200 and the requested plan' do
          plan = create(:plan, org: @user.org)
          plan.add_user!(@user.id, :creator)

          json = fetch_plan_json_response(plan)

          expect(response.code).to eql('200')
          expect(response.headers['Last-Modified']).to eq(plan.updated_at.httpdate)

          expect(json[:id]).to eq(plan.id)
          expect(json[:dmp]).to be_a(Hash)
          identifier = json.dig(:dmp, :dmp_id, :identifier)
          expect(identifier).to be_present
          expect(URI(identifier).path).to eq(api_v2_plan_path(plan))
        end

        context 'when the user does not have an active role on the plan' do
          before do
            other_plan = create(:plan)
            get(dmp_path(other_plan), headers: @headers)
          end

          it_behaves_like 'returns a 404 Plan not found for show'
        end

        context 'when the plan does not exist' do
          before { get(dmp_path(id: 0), headers: @headers) }

          it_behaves_like 'returns a 404 Plan not found for show'
        end
      end
    end
    # TODO: Copy over POST /api/v2/plans specs as a baseline for POST /dmps
    # TODO: Copy over PUT /api/v2/plans/:id specs as a baseline for PUT /dmps/:id
  end
end
