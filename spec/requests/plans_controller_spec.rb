# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'PlansController', type: :request do
  let(:user_org) { create(:org) }
  let(:user) { create(:user, org: user_org) }

  before { sign_in(user) }

  describe 'GET /plans' do
    let!(:user_created_plan) { create(:plan, :creator, creator: user, org: user.org) }

    it 'renders My Plans correctly' do
      get plans_path
      expect(response).to have_http_status(:ok)
      html = Nokogiri::HTML(response.body)

      user_plans_table = html.at_css('table#my-plans')
      expect(user_plans_table.text).to include(user_created_plan.title)
    end
  end

  describe 'GET /plans/new' do
    let(:funding_org) { create(:org, :funder, :institution) }
    let!(:orgs) { [funding_org, create(:org, :organisation)] }

    let(:html) do
      get new_plan_path
      expect(response).to have_http_status(:ok)
      Nokogiri::HTML(response.body)
    end

    it 'has expected form inputs with expected attribute values' do
      # NOTE: Both checkboxes start unchecked, but their checked values differ (1 vs 0).
      # TODO: Standardize checkbox value semantics for consistency.
      {
        # input for plan.title
        '#plan_title' => { name: 'plan[title]' },
        # input for plan.org
        '#plan_org_org_name' => { name: 'plan[org][org_name]' },
        # checkbox for "is test plan"
        '#is_test' => { name: 'is_test', value: '1' },
        # checkbox for "no research org"
        '#plan_no_org' => { name: 'plan_no_org', value: '0' }
      }.each do |selector, attrs|
        element = html.at_css(selector)
        expect(element['name']).to eq(attrs[:name])
        expect(element['value']).to eq(attrs[:value]) if attrs[:value]
      end

      # Available templates div is initially hidden
      available_templates_div = html.at_css('#available-templates')
      expect(available_templates_div['style']).to include('display: none')

      # 'Create plan' and 'Cancel' buttons checks
      submit_button = html.at_css('button[type="submit"]')
      expect(submit_button.text).to eq('Create plan')
      cancel_button = html.at_css('a.btn.btn-secondary[href="/plans"]')
      expect(cancel_button.text).to eq('Cancel')
      # NOTE: `cancel_button` is really a link
      expect(cancel_button['href']).to eq('/plans')
    end

    it 'builds a correct crosswalk for org autocomplete' do
      crosswalk_data = parse_crosswalk_data(html)

      expect(crosswalk_data).to be_an(Array)
      expect(crosswalk_data.size).to eq(orgs.size)
      expect(crosswalk_names(crosswalk_data)).to match_array(orgs.map(&:name))
      expect(crosswalk_ids(crosswalk_data)).to match_array(orgs.map(&:id))
    end
  end

  describe 'POST /plans' do
    let(:default_funder) { create(:org, :funder) }
    let(:default_template) { create(:template, org: default_funder, is_default: true, published: true) }
    let(:user_org_template) { create(:template, :organisationally_visible, org: user.org, published: true) }
    let(:other_org) { create(:org) }
    let(:other_org_template) { create(:template, :organisationally_visible, org: other_org, published: true) }

    before do
      @original_default_funder_id = Rails.application.config.default_funder_id
      Rails.application.config.default_funder_id = default_template.org.id
    end

    after do
      Rails.application.config.default_funder_id = @original_default_funder_id
    end

    # Our tests reference default_template, rather than Template.default
    # This test simply ensures that we are correct in doing so.
    it 'Template.default returns the correct template' do
      expect(Template.default).to eq(default_template)
    end

    RSpec.shared_examples 'create plan' do |template_key, org_key, should_create|
      it "#{should_create ? 'creates' : 'does not create'} a plan" do
        template, org = fetch_template_and_org(template_key, org_key)
        post plans_path, params: post_plans_payload(template, org)

        if should_create
          expect(Plan.count).to_not be_zero
          plan = Plan.last

          expect(response).to have_http_status(:redirect)
          expect(response).to redirect_to(plan_path(plan.id))

          expect(plan.template_id).to eql(template.id)
          # Expect the default plan.title when none is specified in POST request
          expect(plan.title).to eql("#{user.firstname}'s Plan")
          # `plan.org_id` depends on whether or not `org` was included in POST request payload
          expect(plan.org_id).to eql(org ? org.id : user.org_id) if plan.respond_to?(:org_id)
        else
          expect(response).to have_http_status(:redirect)
          expect(response).to redirect_to(new_plan_path)
          follow_redirect!
          expect(flash[:alert]).to eq('Unable to identify a suitable template for your plan.')
          expect(Plan.count).to be_zero
        end
      end
    end

    # TODO: Refactor/extract the matrix of template/org availability checks into
    # spec/services/templates/template_options_service_spec.rb and keep only a small
    # set of focused controller request specs here.
    [
      # POST /plans without `org` sets plan.org = current_user.org
      { template: :default_template },
      { template: :user_org_template },
      { template: :other_org_template, should_create: false },

      # Test plan creation with explicit (template + org) combinations.
      { template: :default_template, org: :default_funder },
      { template: :user_org_template, org: :user_org },
      { template: :other_org_template, org: :other_org },
      { template: :other_org_template, org: :user_org, should_create: false },
      { template: :user_org_template, org: :default_funder, should_create: false }
    ].each do |example|
      include_examples(
        'create plan',
        example[:template],
        example[:org],
        example.fetch(:should_create, true)
      )
    end
  end

  private

  # Constructs and returns the POST /plans payload
  def post_plans_payload(template, org = nil)
    params = {}
    params[:plan] = { template_id: template.id }
    return params unless org

    params[:plan][:org] = {
      id: { id: org.id, name: org.name, sort_name: org.name }.to_json,
      org_name: org.name,
      org_sources: [].to_json,
      org_crosswalk: [].to_json
    }
    params
  end

  def fetch_template_and_org(template_key, org_key)
    template = send(template_key)
    org = org_key ? send(org_key) : nil
    [template, org]
  end

  def parse_crosswalk_data(html)
    crosswalk_json = html.at_css('#plan_org_org_crosswalk')['value']
    JSON.parse(crosswalk_json)
  end

  def crosswalk_names(data)
    data.map { |c| c['name'] }
  end

  def crosswalk_ids(data)
    data.map { |c| c['id'] }
  end
end
