# frozen_string_literal: true

# Controller that determines which templates are displayed/selected for the user when
# they are creating a new plan
class TemplateOptionsController < ApplicationController
  include OrgSelectable

  after_action :verify_authorized

  # GET /template_options  (AJAX)
  # Collect all of the templates available for the org+funder combination
  # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
  # rubocop:disable Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
  def index
    org_hash = plan_params.fetch(:research_org_id, {})

    authorize Template.new, :template_options?

    org = org_from_params(params_in: { org_id: org_hash.to_json }) if org_hash.present?
    funder = Org.find(Rails.application.config.default_funder_id)

    @templates = []

    return unless (org.present? && !org.new_record?) || (funder.present? && !funder.new_record?)

    if org.present? && !org.new_record?
      # Load the funder's template(s)
      @templates = Template.latest_customizable.where(org_id: funder.id).sort_by(&:title).to_a
      # Wherever possible, replace funder templates with organisational customizations
      @templates = @templates.map do |tmplt|
        customization = Template.published
                                .latest_customized_version(tmplt.family_id,
                                                           org.id).first
        # Only provide the customized version if it's still up to date with the funder template
        if customization.present? && !customization.upgrade_customization?
          customization
        else
          tmplt
        end
      end
      # We are using a default funder to provide with the default templates, but
      # We still want to provide the organization templates.
      # Retrieve the Org's templates
      @templates << Template.published.organisationally_visible.where(org_id: org.id,
                                                                      customization_of: nil).sort_by(&:title).to_a
    else
      # if'No Primary Research Institution' checkbox is checked,
      # only show publicly available template without customization
      @templates << Template.published.publicly_visible.where(org_id: funder.id,
                                                              customization_of: nil).sort_by(&:title).to_a
    end
    @templates = @templates.flatten

    @templates = sort_templates(@templates, org)
  end
  # rubocop:enable Metrics/AbcSize, Metrics/MethodLength
  # rubocop:enable Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity

  private

  def plan_params
    params.require(:plan).permit(research_org_id: org_params,
                                 funder_id: org_params)
  end

  def org_params
    %i[id name url language abbreviation ror fundref weight score]
  end

  def alliance_templates(templates)
    simplified = templates.find { |t| t.title.start_with?('Alliance Simplified Template') }
    alliance   = templates.find { |t| t.title == 'Alliance Template' }
    [simplified, alliance].compact
  end

  # Assign the order of templates in the dropdown menu
  # The desired order of templates in the dropdown is:
  # All organizational templates first followed by the Alliance Simplified Template
  # Followed by the Alliance Template and then all remaining templates
  def sort_templates(templates, org)
    # Get all templates belonging to the selected organization
    org_templates = templates.select { |template| template.org_id == org&.id }
    # Get the Alliance Simplified and Full Templates
    alliance_templates = alliance_templates(templates)

    org_is_alliance = org&.name == 'Digital Research Alliance of Canada'

    # If the chosen org is the Alliance, its templates must not be removed
    remaining_templates = if org_is_alliance
                            templates - alliance_templates
                          else
                            templates - org_templates - alliance_templates
                          end

    if org_is_alliance
      (alliance_templates + remaining_templates).uniq
    else
      (org_templates + alliance_templates + remaining_templates).uniq
    end
  end
end
