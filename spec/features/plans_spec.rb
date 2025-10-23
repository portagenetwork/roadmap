# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Plans', type: :feature do
  include Webmocks

  before do
    @org = create(:org)
    @research_org = create(:org, :organisation, :research_institute,
                           name: 'Test Research Org', templates: 1)
    # Create the required default_funder org for DMP Assistant
    @funding_org  = create(:org, :funder, templates: 1)
    # Create the default template for the default_funder
    @default_template = create(:template, :default, :published, org_id: @funding_org.id)
    @original_default_funder_id = Rails.application.config.default_funder_id
    Rails.application.config.default_funder_id = @funding_org.id
    @template     = create(:template, org: @org)
    @user         = create(:user, org: @org)
    sign_in(@user)
  end

  after do
    Rails.application.config.default_funder_id = @original_default_funder_id
  end

  it 'User creates a new Plan', :js do
    click_link 'Create plan'
    fill_in :plan_title, with: 'My test plan'
    choose_suggestion('plan_org_org_name', @research_org)

    find('#templateDropdown').click

    within('#template-dropdown-menu') do
      click_link @default_template.title
    end
    click_button 'Create plan'

    # Expectations
    expect(find('#notification-area')).to have_text(
      "Notice: Successfully created the plan.\nThis plan is based on the default template."
    )
    @plan = Plan.last
    expect(@user.plans).to be_one
    expect(current_path).to eql(plan_path(@plan))
    expect(page).to have_css("input[type=text][value='#{@plan.title}']")
    expect(@plan.title).to eql('My test plan')
    expect(@plan.org_id).to eql(@research_org.id)
    expect(@plan.template_id).to eql(@default_template.id)
  end
end
