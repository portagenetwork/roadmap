# frozen_string_literal: true

# Controller that determines which templates are displayed/selected for the user when
# they are creating a new plan
class TemplateOptionsController < ApplicationController
  include OrgSelectable

  after_action :verify_authorized

  # GET /template_options  (AJAX)
  # Collect all of the templates available for the org+funder combination
  def index
    org_hash = plan_params.fetch(:research_org_id, {})

    authorize Template.new, :template_options?

    org = org_from_params(params_in: { org_id: org_hash.to_json }) if org_hash.present?

    @templates = Templates::TemplateOptionsService.available_templates(org)

    respond_to do |format|
      format.json { render json: build_templates_payload(@templates) }
    end
  end

  private

  def plan_params
    params.require(:plan).permit(research_org_id: org_params,
                                 funder_id: org_params)
  end

  def org_params
    %i[id name url language abbreviation ror fundref weight score]
  end

  # Returns a JSON payload with the following structure:
  # - templates:
  #   - org_templates: [All non-funder templates]
  #   - priority_templates: [The simplified and default funder templates]
  #   - other_templates: [All non-priority funder templates]
  # - total_templates: Count of all templates
  def build_templates_payload(templates)
    funder_templates = templates.select { |t| t.org_id == Rails.application.config.default_funder_id }
    simplified = funder_templates.find { |t| t.title == _('Alliance Simplified Template (Funding Application Stage)') }
    default = funder_templates.find(&:is_default)
    priority_templates = [simplified, default].compact

    { templates: { org_templates: templates - funder_templates,
                   priority_templates: priority_templates,
                   other_templates: funder_templates - priority_templates },
      total_templates: templates.size }
  end
end
