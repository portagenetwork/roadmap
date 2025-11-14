# frozen_string_literal: true

# Controller that determines which templates are displayed/selected for the user when
# they are creating a new plan
class TemplateOptionsController < ApplicationController
  include OrgSelectable

  after_action :verify_authorized

  DEFAULT_FUNDER_ID = Rails.application.config.default_funder_id

  # GET /template_options  (AJAX)
  # Collect all of the templates available for the org+funder combination
  # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
  # rubocop:disable Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
  def index
    org_hash = plan_params.fetch(:research_org_id, {})

    authorize Template.new, :template_options?

    org = org_from_params(params_in: { org_id: org_hash.to_json }) if org_hash.present?
    funder = Org.find(DEFAULT_FUNDER_ID)

    @templates = []

    return unless (org.present? && !org.new_record?) || (funder.present? && !funder.new_record?)

    if org.present? && !org.new_record?
      # Load the funder's template(s)
      # (`Template.default` belongs to `funder` and will be fetched as part of this query)
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
      # (`Template.default` belongs to `funder` and will be fetched as part of this query)
      @templates << Template.published.publicly_visible.where(org_id: funder.id,
                                                              customization_of: nil).sort_by(&:title).to_a
    end
    @templates = @templates.flatten

    respond_to do |format|
      format.json { render json: build_templates_payload(@templates) }
    end
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

  # Returns a JSON payload with the following structure:
  # - templates:
  #   - org_templates: [All non-funder templates]
  #   - priority_templates: [The simplified and default funder templates]
  #   - other_templates: [All non-priority funder templates]
  # - total_templates: Count of all templates
  def build_templates_payload(templates)
    funder_templates = templates.select { |t| t.org_id == DEFAULT_FUNDER_ID }
    simplified = funder_templates.find { |t| t.title == _('Alliance Simplified Template (Funding Application Stage)') }
    default = funder_templates.find(&:is_default)
    priority_templates = [simplified, default].compact

    { templates: { org_templates: templates - funder_templates,
                   priority_templates: priority_templates,
                   other_templates: funder_templates - priority_templates },
      total_templates: templates.size }
  end
end
