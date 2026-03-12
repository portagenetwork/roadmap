# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Plans', type: :feature do
  include Webmocks

  before do
    # Create an org to be selected from the dropdown
    # (The associated template will serve as an ORGANISATIONAL TEMPLATE)
    @org = create(:org, :organisation, :research_institute,
                  name: 'Test Research Org', templates: 1)
    # Create the required default_funder org for DMP Assistant
    @funding_org = create(:org, :funder)
    @original_default_funder_id = Rails.application.config.default_funder_id
    Rails.application.config.default_funder_id = @funding_org.id
    # Create the required default template (also serves as an ALLIANCE GENERAL TEMPLATE)
    @default_template = create(:template, :default, :published, org_id: @funding_org.id)
    # Create an ADDITIONAL ALLIANCE TEMPLATE
    @extra_funder_template = create(:template, :published, :publicly_visible, org_id: @funding_org.id)
    @user = create(:user, org: create(:org))
    sign_in(@user)
  end

  after do
    Rails.application.config.default_funder_id = @original_default_funder_id
  end

  it 'User creates a new Plan', :js do
    find('#create-plan-link').click
    fill_in :plan_title, with: 'My test plan'
    choose_suggestion('plan_org_org_name', @org)

    # Open the dropdown
    find('#template-dropdown').click

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
    expect(@plan.org_id).to eql(@org.id)
    expect(@plan.template_id).to eql(@default_template.id)
  end

  it 'displays template dropdown headers and expands more templates', :js do
    find('#create-plan-link').click
    fill_in :plan_title, with: 'My test plan'
    choose_suggestion('plan_org_org_name', @org)

    # Open the dropdown
    find('#template-dropdown').click

    within('#template-dropdown-menu') do
      expect(page).to have_content('ORGANISATIONAL TEMPLATES')
      expect(page).to have_content('ALLIANCE GENERAL TEMPLATES')
      expect(page).to have_content('Show more templates')
    end

    click_button 'Show more templates'

    within('#extra-templates') do
      expect(page).to have_content('ADDITIONAL ALLIANCE TEMPLATES')
      expect(page).to have_selector('.dropdown-item', minimum: 1)
    end
  end
end
