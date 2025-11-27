# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'PlansController', type: :request do
  let(:user) { create(:user) }

  before { sign_in(user) }

  describe 'GET /plans' do
    let!(:user_created_plan) { create(:plan, :creator, creator: user, org: user.org) }
    let!(:admin_for_user_org) { create(:user, :org_admin, org: user.org) }
    let!(:admin_for_other_org) { create(:user, :org_admin, org: create(:org)) }
    let!(:visible_plan_by_admin_from_same_org) do
      create(:plan, :organisationally_visible, :creator, creator: admin_for_user_org, org: user.org, complete: true)
    end
    let!(:visible_plan_by_admin_from_other_org) do
      create(:plan, :organisationally_visible, :creator, creator: admin_for_other_org, org: admin_for_other_org.org,
                                                         complete: true)
    end

    it 'Renders My Plans and organisationally visible plans correctly' do
      get plans_path
      expect(response).to have_http_status(:ok)
      html = Nokogiri::HTML(response.body)

      user_plans_table = html.at_css('table#my-plans')
      expect(user_plans_table.text).to include(user_created_plan.title)

      # NOTE: id="my-plans" exists for table belonging to user plans
      # TODO: Add something like id="org-plans" to the table listing org plans
      # (See app/views/paginable/plans/_organisationally_or_publicly_visible.html.erb)
      expect(response.body).to include(visible_plan_by_admin_from_same_org.title)
      expect(response.body).to_not include(visible_plan_by_admin_from_other_org.title)
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
      cancel_button = html.at_css('a.btn.btn-default[href="/plans"]')
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
    let(:template) { create(:template, published: true) }
    let(:unpublished_template) { create(:template) }

    it 'creates a plan when only the template_id is provided' do
      post plans_path, params: {
        plan: { template_id: template.id }
      }
      plan = Plan.last
      expect(response).to have_http_status(:redirect)
      expect(response).to redirect_to(plan_path(plan.id))

      expect(plan.template_id).to eql(template.id)
      # Ensure plan.title is as expected when none is provided
      expect(plan.title).to eql("#{user.firstname}'s Plan")
      # Ensure plan.org_id == user.org_id when none is provided
      expect(plan.org_id).to eql(user.org_id)
    end

    it 'does not create a plan when the associated template is unpublished' do
      post plans_path, params: {
        plan: { template_id: unpublished_template.id }
      }
      expect(response).to have_http_status(:redirect)
      expect(response).to redirect_to(new_plan_path)
      follow_redirect!

      # Verify the expected flash message is rendered
      expect(flash[:alert]).to eq('Unable to identify a suitable template for your plan.')

      # Ensure a Plan was not created
      expect(Plan.count).to be_zero
    end
  end

  private

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
