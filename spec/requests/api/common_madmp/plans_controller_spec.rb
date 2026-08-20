# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Api::V2::PlansController do
  include ApiHelper
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
      get(api_v2_plans_path, headers: @headers)
      expect(response).to render_template('api/v2/_standard_response')
      expect(response).to render_template('api/v2/plans/index')
      JSON.parse(response.body).with_indifferent_access
    end

    def fetch_plan_json_response(plan)
      get(api_v2_plan_path(plan), headers: @headers)
      expect(response).to render_template('api/v2/_standard_response')
      expect(response).to render_template('api/v2/plans/index')
      JSON.parse(response.body).with_indifferent_access
    end

    def expect_invalid_token_response # rubocop:disable Metrics/AbcSize
      headers = @headers.merge('Authorization' => "Bearer #{SecureRandom.uuid}")
      yield(headers)

      expect(response.code).to eql('401')
      expect(response.body).to be_empty
      expect(response.headers['WWW-Authenticate']).to match(
        /Bearer realm="Doorkeeper", error="invalid_token", error_description="The access token is invalid"/
      )
    end

    def expect_insufficient_scope_response
      read_only_client = create(:oauth_application, scopes: 'read')
      token = mock_authorization_code_token(oauth_application: read_only_client, user: @user).plaintext_token
      headers = @headers.merge('Authorization' => "Bearer #{token}")
      yield(headers)

      expect(response.code).to eql('403')
    end

    describe 'GET /api/v2/plans (index)' do
      context 'an invalid API token is included' do
        it 'returns a 401 and the expected Oauth 2.0 headers' do
          expect_invalid_token_response { |headers| get(api_v2_plans_path, headers: headers) }
        end
      end

      context 'a valid API token is included' do
        let(:json) { fetch_plans_json_response }
        it 'returns a 200 and the expected response body' do
          # Items array is empty
          expect(json[:items]).to eq([])

          # total_items reflects that nothing is returned
          expect(json[:total_items]).to eq(0)

          # Status code and message are correct
          expect(json[:code]).to eq(200)
          expect(json[:message]).to eq('OK')

          # Application and source are present and sensible
          expect(json[:application]).to eq(ApplicationService.application_name)
          expect(json[:source]).to eq('GET /api/v2/plans')

          # Time is present and parseable
          expect { Time.iso8601(json[:time]) }.not_to raise_error

          # Caller is included
          expect(json[:caller]).to eq(@client.name)
        end

        it 'returns an empty array if no plans are available' do
          # Items array is empty
          expect(json[:items]).to eq([])

          # total_items reflects that nothing is returned
          expect(json[:total_items]).to eq(0)
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

          # Api::V2::PlanPresenter.identifier uses api_v2_plan_url(@plan) to set the "identifier".
          # That url is constructed using `request.host` / "www.example.com"
          # api_v2_plan_url(@plan) within this test will construct the url via
          # default_url_options[:host] / "example.org"
          # Because the urls are misaligned, we will only compare the paths here.
          # TODO: Consider aligning default_url_options[:host] (in test.rb) with `request.host`
          returned_identifiers = json[:items].map { |item| item[:dmp][:dmp_id][:identifier] }
          returned_paths = returned_identifiers.map { |url| URI(url).path }
          expected_paths = included_plans.map { |plan| api_v2_plan_path(plan) }
          expect(returned_paths).to eq(expected_paths)
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
      end
    end

    describe 'GET /api/v2/plans/:id (show)' do
      context 'an invalid API token is included' do
        it 'returns a 401 and the expected Oauth 2.0 headers' do
          plan = create(:plan)
          expect_invalid_token_response { |headers| get(api_v2_plan_path(plan), headers: headers) }
        end
      end

      context 'a valid API token is included' do
        shared_examples 'returns a 404 Plan not found for show' do
          it do
            expect(response.code).to eql('404')
            expect(response).to render_template('api/v2/error')

            json = JSON.parse(response.body).with_indifferent_access
            expect(json[:items]).to eq([])
            expect(json[:errors]).to eq(['Plan not found'])
          end
        end

        it 'returns a 200 and the requested plan' do
          plan = create(:plan, org: @user.org)
          plan.add_user!(@user.id, :creator)

          json = fetch_plan_json_response(plan)

          expect(response.code).to eql('200')
          expect(json[:items].length).to eq(1)
          expect(json[:total_items]).to eq(1)
          expect(json[:code]).to eq(200)
          expect(json[:message]).to eq('OK')
          expect(json[:application]).to eq(ApplicationService.application_name)
          expect(json[:source]).to eq("GET /api/v2/plans/#{plan.id}")
          expect { Time.iso8601(json[:time]) }.not_to raise_error
          expect(json[:caller]).to eq(@client.name)

          identifier = json.dig(:items, 0, :dmp, :dmp_id, :identifier)
          expect(identifier).to be_present
          expect(URI(identifier).path).to eq(api_v2_plan_path(plan))
        end

        context 'when the user does not have an active role on the plan' do
          before do
            other_plan = create(:plan)
            get(api_v2_plan_path(other_plan), headers: @headers)
          end

          it_behaves_like 'returns a 404 Plan not found for show'
        end

        context 'when the plan does not exist' do
          before { get(api_v2_plan_path(id: 0), headers: @headers) }

          it_behaves_like 'returns a 404 Plan not found for show'
        end
      end
    end

    describe 'POST /api/v2/plans - create' do
      before(:each) do
        stub_ror_service
        mock_identifier_schemes
        create(:template, :publicly_visible, is_default: true, published: true)
        @json = JSON.parse(complete_create_json).with_indifferent_access
      end

      context 'an invalid API token is included' do
        it 'returns a 401 and the expected Oauth 2.0 headers' do
          expect_invalid_token_response { |headers| post(api_v2_plans_path, params: @json, headers: headers) }
        end

        it 'returns 403 if the OAuth app does not have the `write` scope' do
          expect_insufficient_scope_response do |headers|
            post(api_v2_plans_path, params: @json.to_json, headers: headers)
          end
        end
      end

      context 'minimal JSON' do
        before(:each) do
          @json = JSON.parse(minimal_create_json).with_indifferent_access
        end

        it 'returns a 400 if the incoming JSON is invalid' do
          post api_v2_plans_path, params: Faker::Lorem.word.to_json, headers: @headers
          expect(response.code).to eql('400')
          expect(response).to render_template('api/v2/error')

          json = JSON.parse(response.body).with_indifferent_access
          expect(json[:errors]).to eql('Invalid JSON format')
          expect(json[:details]).to be_nil
        end

        it 'returns a 400 if the incoming JSON contains unescaped quotes' do
          malformed_json = '{"dmp": {"title": "hel"lo"}}'

          post api_v2_plans_path, params: malformed_json, headers: @headers

          expect(response.code).to eql('400')
          expect(response).to render_template('api/v2/error')

          json = JSON.parse(response.body).with_indifferent_access
          expect(json[:errors]).to eql('Invalid JSON format')
          expect(json.dig(:details, :error_code)).to eql('invalid_json')
          expect(json.dig(:details, :hint)).to eql(
            'Check for malformed JSON (for example, unescaped quotes inside string values).'
          )
        end

        it 'returns a 201 if the incoming JSON is valid' do
          post api_v2_plans_path, params: @json.to_json, headers: @headers
          expect(response.code).to eql('201')
          expect(response).to render_template('api/v2/plans/index')
        end
      end

      context 'complete JSON' do
        before(:each) do
          @json = JSON.parse(complete_create_json).with_indifferent_access
        end

        it 'returns a 201 if the incoming JSON is valid' do
          post api_v2_plans_path, params: @json.to_json, headers: @headers
          expect(response.code).to eql('201')
          expect(response).to render_template('api/v2/plans/index')
        end

        xit 'fails if the Plan already exists (based on the specified :dmp_id)' do
          # SKIPPED: The plan existence check is not currently implemented.
          # See DMPTool app/controllers/api/v2/plans_controller.rb for plan_exists?(json:),
          # NOTE: Although it is defined, DmpTool does not use plan_exists?(json:) either.
          plan = create(:plan)
          id = @json[:dmp].fetch(:dmp_id, {})[:identifier]
          create(:identifier, identifiable: plan, value: id, identifier_scheme: @scheme)
          post(api_v2_plans_path, params: @json.to_json, headers: @headers)

          expect(response.code).to eql('400')
          expect(response).to render_template('api/v2/_standard_response')
          expect(response).to render_template('api/v2/error')

          json = JSON.parse(response.body).with_indifferent_access
          expect(json[:items].empty?).to be(true)
          expect(json[:errors].length).to be(1)
          expect(json[:errors].first).to eql('Plan already exists. Send an update instead.')
        end

        it 'fails if invalid JSON is passed' do
          Api::V2::Deserialization::Plan.stubs(:deserialize).raises(JSON::ParserError)
          post(api_v2_plans_path, params: @json.to_json, headers: @headers)

          expect(response.code).to eql('400')
          expect(response).to render_template('api/v2/_standard_response')
          expect(response).to render_template('api/v2/error')

          json = JSON.parse(response.body).with_indifferent_access
          expect(json[:items].empty?).to be(true)
          expect(json[:errors].length).to be(1)
          expect(json[:errors].first).to eql('Invalid JSON')
        end

        it 'fails if the JSON could not be deserialized to a Plan' do
          Api::V2::Deserialization::Plan.stubs(:deserialize).returns(nil)
          post(api_v2_plans_path, params: @json.to_json, headers: @headers)

          expect(response.code).to eql('400')
          expect(response).to render_template('api/v2/_standard_response')
          expect(response).to render_template('api/v2/error')

          json = JSON.parse(response.body).with_indifferent_access
          expect(json[:items].empty?).to be(true)
          expect(json[:errors].length).to be(1)
          expect(json[:errors].first).to eql('Invalid JSON')
        end

        it 'returns contextualized errors' do
          @json[:dmp][:title] = {}
          post(api_v2_plans_path, params: @json.to_json, headers: @headers)

          expect(response.code).to eql('400')
          expect(response).to render_template('api/v2/_standard_response')
          expect(response).to render_template('api/v2/error')

          json = JSON.parse(response.body).with_indifferent_access
          expect(json[:items].empty?).to be(true)
          expect(json[:errors].length).to be(1)
          expect(json[:errors].first).to eql(':title is a required field')
        end

        it 'creates the Plan' do
          post(api_v2_plans_path, params: @json.to_json, headers: @headers)

          expect(response.code).to eql('201'), "Unable to create Plan: #{response.body.inspect}"
          expect(response).to render_template('api/v2/_standard_response')
          expect(response).to render_template('api/v2/identifiers/_show')
          expect(response).to render_template('api/v2/orgs/_show')
          expect(response).to render_template('api/v2/contributors/_show')
          expect(response).to render_template('api/v2/plans/_funding')
          expect(response).to render_template('api/v2/plans/_project')
          expect(response).to render_template('api/v2/datasets/_show')
          expect(response).to render_template('api/v2/plans/_show')
          expect(response).to render_template('api/v2/plans/index')

          original = @json[:dmp]
          json = JSON.parse(response.body).with_indifferent_access
          created = json.fetch(:items, [{ dmp: {} }]).first[:dmp]
          dmp = Plan.find_by(id: created.fetch(:dmp_id, {})[:identifier].split('/').last)

          expect(dmp.present?).to be(true)
          expect(created[:title]).to eql(original[:title])
          expect(dmp.title).to eql(original[:title])

          expect(created[:description]).to eql(original[:description])
          expect(dmp.description).to eql(original[:description])

          # Defaulting lang to English for now since the Plan does not retain this info
          expect(created[:language]).to eql('eng')

          expect(created[:created]).to eql(dmp.created_at.to_formatted_s(:iso8601))
          expect(created[:modified]).to eql(dmp.updated_at.to_formatted_s(:iso8601))

          expect(created[:ethical_issues_exist]).to eql(original[:ethical_issues_exist])
          bool = Api::V2::ConversionService.yes_no_unknown_to_boolean(created[:ethical_issues_exist])
          expect(bool).to eql(dmp.ethical_issues)
          expect(created[:ethical_issues_description]).to eql(original[:ethical_issues_description])
          expect(created[:ethical_issues_report]).to eql(original[:ethical_issues_report])

          expect(created[:dmp_id][:type]).to eql('url')
          expect(created[:dmp_id][:identifier].end_with?(api_v2_plan_path(dmp))).to be(true)

          # Contact verification
          expect(created[:contact][:mbox]).to eql(@user.email)
          expect(created[:contact][:name]).to eql(@user.name(false))
          expect(created[:contact][:affiliation][:name]).to eql(@user.org.name)
          expect(created[:contact][:mbox]).to eql(dmp.owner.email)
          expect(created[:contact][:name]).to eql(dmp.owner.name(false))
          expect(created[:contact][:affiliation][:name]).to eql(dmp.owner.org.name)

          # Contributor verification
          expect(created[:contributor].length).to eql(original[:contributor].length)
          created[:contributor].each do |contributor|
            orig_contrib = original[:contributor].select do |c|
              c[:mbox] == contributor[:mbox] || c[:name] == contributor[:name]
            end

            contrib = Contributor.find_by(email: orig_contrib.first[:mbox])
            expect(contributor[:name]).to eql(orig_contrib.first[:name])
            expect(contributor[:mbox]).to eql(orig_contrib.first[:mbox])

            # If the request body affiliation was an existing org,
            # make sure that affiliation is included in the response body.
            org = Org.find_by(name: orig_contrib.first.dig(:affiliation, :name))
            expect(contributor[:affiliation].present?).to eq(org.present?)

            expect(contributor[:name]).to eql(contrib.name)
            expect(contributor[:mbox]).to eql(contrib.email)

            contributor[:role].each do |role|
              expect(orig_contrib.first[:role].include?(role)).to be(true)
              r = Api::V2::DeserializationService.translate_role(role: role)
              expect(contrib.send(:"#{r}?")).to be(true)
            end
          end

          # Project Verification
          project = created.fetch(:project, [{}]).first
          # There is no Project model so the project->title and project->description should be
          # the same as the Plan's
          expect(created[:title]).to eql(project[:title])
          expect(created[:description]).to eql(project[:description])
          expect(Time.zone.parse(project[:start])).to eql(Time.zone.parse(original.fetch(:project, [{}]).first[:start]))
          expect(Time.zone.parse(project[:end])).to eql(Time.zone.parse(original.fetch(:project, [{}]).first[:end]))
          expect(project[:start]).to eql(dmp.start_date.to_formatted_s(:iso8601))
          expect(project[:end]).to eql(dmp.end_date.to_formatted_s(:iso8601))

          # Funding Verification
          funding = created.fetch(:project, [{}]).first.fetch(:funding, [{}]).first
          orig_funding = original.fetch(:project, [{}]).first.fetch(:funding, [{}]).first
          expect(funding[:name]).to eql(orig_funding[:name])
          expect(funding[:funding_status]).to eql(orig_funding[:funding_status])
          expect(funding[:grant_id][:identifier]).to eql(orig_funding[:grant_id][:identifier])
          opp_id = funding[:dmproadmap_funding_opportunity_id][:identifier]
          expect(opp_id).to eql(orig_funding[:dmproadmap_funding_opportunity_id][:identifier])

          # Template verification
          expected_template = Api::V2::Deserialization::Plan.send(:find_template, json: original)
          expect(dmp.template).to eql(expected_template)
        end

        # Skipping this test because plan.owner is now always the User that made the POST request
        # Re-enable this test when plan.owner is again derived from dmp[:contact]
        xit 'sends both a `invite` and a `sharing_notification` email if the :contact is not already a User' do
          ActionMailer::Base.deliveries = []
          post(api_v2_plans_path, params: @json.to_json, headers: @headers)

          expect(response.code).to eql('201'), "Unable to create Plan: #{response.body.inspect}"
          expect(ActionMailer::Base.deliveries).to have_exactly(2).item
          expect(response).to render_template('devise/mailer/invitation_instructions')
          expect(response).to render_template('user_mailer/sharing_notification')

          owner = Plan.find_by(title: @json[:dmp][:title]).owner
          expect(owner.firstname.present?).to be(true)
          expect(owner.surname.present?).to be(true)
          expect(owner.email.present?).to be(true)
          expect(owner.org.present?).to be(true)
          expect(owner.invitation_token.present?).to be(true)
          expect(owner.invitation_created_at.present?).to be(true)
          expect(owner.invitation_sent_at.present?).to be(true)
          expect(owner.plans.length).to be(1)
        end

        # Skipping this test because plan.owner is now always the User that made the POST request
        # Re-enable this test when plan.owner is again derived from dmp[:contact]
        xit 'sends an email notification of the new plan if the :contact is already a User' do
          contact = @json[:dmp][:contact]
          name_parts = contact[:name].split
          create(:user, firstname: name_parts.first, surname: name_parts.last, email: contact[:mbox])

          ActionMailer::Base.deliveries = []
          post(api_v2_plans_path, params: @json.to_json, headers: @headers)

          expect(response.code).to eql('201'), "Unable to create Plan: #{response.body.inspect}"
          expect(ActionMailer::Base.deliveries).to have_exactly(1).item
          expect(response).to render_template('user_mailer/sharing_notification')

          owner = Plan.find_by(title: @json[:dmp][:title]).owner
          expect(owner.firstname.present?).to be(true)
          expect(owner.surname.present?).to be(true)
          expect(owner.email.present?).to be(true)
          expect(owner.org.present?).to be(true)
          expect(owner.invitation_token.present?).to be(false)
          expect(owner.invitation_created_at.present?).to be(false)
          expect(owner.invitation_sent_at.present?).to be(false)
          expect(owner.plans.length).to be(1)
        end
      end
    end

    describe 'PUT /api/v2/plans/:id - update' do
      before(:each) do
        # Setup a template with questions and a plan for the user
        @template = create(:template, :publicly_visible, published: true)
        @question1 = create(:question, :textarea, section: create(:section, template: @template))
        @question2 = create(:question, :textarea, section: create(:section, template: @template))

        @plan = create(:plan, template: @template)
        @plan.add_user!(@user.id, :creator)
      end

      context 'an invalid API token is included' do
        it 'returns a 401 and the expected Oauth 2.0 headers' do
          expect_invalid_token_response { |headers| put(api_v2_plan_path(@plan), headers: headers) }
        end

        it 'returns 403 if the OAuth app does not have the `write` scope' do
          payload = { answers: [] }
          expect_insufficient_scope_response do |headers|
            put(api_v2_plan_path(@plan), params: payload.to_json, headers: headers)
          end
        end
      end

      context 'validating question ownership' do
        it 'returns a 400 if a question does not belong to the plan template' do
          other_question = create(:question, :textarea) # Belongs to a different template
          payload = {
            answers: [{ question_id: other_question.id, value: 'This should fail' }]
          }

          put api_v2_plan_path(@plan), params: payload.to_json, headers: @headers

          expect(response.code).to eql('400')
          json = JSON.parse(response.body).with_indifferent_access
          expect(json[:errors].first).to include("do not belong to this plan's template")
        end
      end

      context 'updating answers' do
        it 'creates a new answer if one does not exist' do
          payload = {
            answers: [{ question_id: @question1.id, value: 'New answer text' }]
          }

          expect do
            put api_v2_plan_path(@plan), params: payload.to_json, headers: @headers
          end.to change(Answer, :count).by(1)

          expect(response.code).to eql('200')
          expect(@plan.answers.find_by(question_id: @question1.id).text).to eq('New answer text')
        end

        it 'updates an existing answer if it already exists' do
          existing_answer = create(:answer, plan: @plan, question: @question1, user: @user, text: 'Old text')

          payload = {
            answers: [{ question_id: @question1.id, value: 'Updated text' }]
          }

          expect do
            put api_v2_plan_path(@plan), params: payload.to_json, headers: @headers
          end.not_to change(Answer, :count)

          expect(response.code).to eql('200')
          expect(existing_answer.reload.text).to eq('Updated text')
        end

        it 'can update multiple answers at once (existing and new)' do
          # One existing, one new
          create(:answer, plan: @plan, question: @question1, user: @user, text: 'Old text')

          payload = {
            answers: [
              { question_id: @question1.id, value: 'Updated text' },
              { question_id: @question2.id, value: 'Brand new answer' }
            ]
          }

          expect do
            put api_v2_plan_path(@plan), params: payload.to_json, headers: @headers
          end.to change(Answer, :count).by(1)

          expect(response.code).to eql('200')
          expect(@plan.answers.find_by(question_id: @question2.id).text).to eq('Brand new answer')
        end
      end

      context 'detects an invalid request' do
        it 'returns a 400 if the answers payload is missing or not an array' do
          payload = { answers: 'not an array' }
          put api_v2_plan_path(@plan), params: payload.to_json, headers: @headers

          expect(response.code).to eql('400')
          expected_error = _('Invalid or missing answers payload. Each answer must be an object with an ' \
                             'integer question_id and value. Example: ' \
                             '{"answers":[{"question_id":999,"value":"Updated answer."}]}')

          expect(JSON.parse(response.body)['errors']).to include(expected_error)
        end

        it 'returns a 404 if the plan does not exist' do
          put api_v2_plan_path(id: 0), params: { answers: [] }.to_json, headers: @headers

          expect(response.code).to eql('404')
          json = JSON.parse(response.body).with_indifferent_access
          expect(json[:errors]).to eq(['Plan not found'])
        end

        it 'returns a 404 if the user has no role on the plan' do
          other_plan = create(:plan) # No role for @user
          put api_v2_plan_path(other_plan), params: { answers: [] }.to_json, headers: @headers

          expect(response.code).to eql('404')
          json = JSON.parse(response.body).with_indifferent_access
          expect(json[:errors]).to eq(['Plan not found'])
        end

        it 'returns a 403 if the user has a role but insufficient permissions to update' do
          # Create a plan where @user has commenter role (read-only)
          commenter_plan = create(:plan)
          commenter_plan.add_user!(@user.id, :commenter)

          # (Double-check @user has a commenter role on the plan)
          role = commenter_plan.roles.find_by(user_id: @user.id, active: true)
          expect(role).to be_present
          expect(role.commenter).to be(true)
          # Ensure commenter role doesn't allow @user to edit/update the plan
          expect(commenter_plan.editable_by?(@user.id)).to be(false)
          expect(Api::V2::PlansPolicy.new(@user, commenter_plan).update?).to be(false)

          put api_v2_plan_path(commenter_plan), params: { answers: [] }.to_json, headers: @headers

          expect(response.code).to eql('403')
          json = JSON.parse(response.body).with_indifferent_access
          expect(json[:message]).to eq(['The client is not authorized to perform this action.'])
        end

        it 'returns a 400 if the question format is not a text field' do
          # Do not specify textarea or textfield
          @bad_question = create(:question, section: create(:section, template: @template))
          create(:answer, plan: @plan, question: @bad_question, user: @user, text: 'Old text')

          payload = {
            answers: [
              { question_id: @bad_question.id, value: 'Updated text' }
            ]
          }

          put api_v2_plan_path(@plan), params: payload.to_json, headers: @headers
          expect(response.code).to eql('400')
          expect(JSON.parse(response.body)['errors']).to include(
            'Only plain text answers are currently allowed. ' \
            "Question(s) #{@bad_question.id} do not support that format."
          )
        end

        it 'returns a 400 if the payload has duplicate question IDs' do
          create(:answer, plan: @plan, question: @question1, user: @user, text: 'Old text')

          payload = {
            answers: [
              { question_id: @question1.id, value: 'Updated text' },
              { question_id: @question1.id, value: 'Second updated text' }
            ]
          }

          put api_v2_plan_path(@plan), params: payload.to_json, headers: @headers
          expect(response.code).to eql('400')
          expect(JSON.parse(response.body)['errors']).to include('Duplicate question ids found in payload')
        end
      end
    end
  end
end
