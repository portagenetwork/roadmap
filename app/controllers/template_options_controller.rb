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

    @templates = sort_templates(@templates, org)

    # Tag each template with a source
    # Org and priority funder templates to be displayed first
    # Followed by "Show more templates" button to display other templates
    @templates = @templates.map do |t|
      source = if t.org_id == org&.id
                 'org_template'
               elsif t.is_default || (t.title.start_with?('Alliance Simplified Template') &&
                t.org_id == Rails.application.config.default_funder_id)
                 'priority_funder'
               else
                 'other'
               end
      t.as_json.merge(source: source)
    end

    respond_to do |format|
      format.json { render json: { templates: @templates } }
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

  # Orders templates for dropdown:
  # 1. Org templates
  # 2. Priority funder templates (Simplified, Default)
  # 3. Remaining funder templates
  def sort_templates(templates, org)
    # Get the funder templates with the Priority templates ordered in front
    sorted_funder_templates = sort_funder_templates(templates)

    # If an org was selected and the selected org is not the default funder
    if org&.id && org.id != Rails.application.config.default_funder_id
      # Return the templates with the org templates ordered in front
      org_templates = templates.select { |t| t.org_id == org.id }
      org_templates + sorted_funder_templates
    # else, either no org or default_funder was selected
    else
      # All of the templates are funder templates
      sorted_funder_templates
    end
  end

  # Orders funder templates:
  # 1. Priority (Simplified, Default)
  # 2. Remaining funder templates
  def sort_funder_templates(templates)
    funder_templates = templates.select { |t| t.org_id == Rails.application.config.default_funder_id }

    # Identify priority templates
    # NOTE: This will have to be updated if the `simplified` template is ever renamed
    simplified = funder_templates.find { |t| t.title.start_with?('Alliance Simplified Template') }
    default   = funder_templates.find(&:is_default)
    priority  = [simplified, default].compact

    # Return priority first, then remaining funder templates
    priority + (funder_templates - priority)
  end
end
