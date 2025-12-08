# frozen_string_literal: true

module Templates
  # Service for retrieving templates available to a given organization.
  class TemplateOptionsService
    # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
    # rubocop:disable Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
    def self.available_templates(org)
      funder = Org.find_by(id: Rails.application.config.default_funder_id)

      templates = []

      return templates unless (org.present? && !org.new_record?) || (funder.present? && !funder.new_record?)

      if org.present? && !org.new_record?
        # Load the funder's template(s)
        # (`Template.default` belongs to `funder` and will be fetched as part of this query)
        templates = Template.latest_customizable.where(org_id: funder.id).sort_by(&:title).to_a
        # Wherever possible, replace funder templates with organisational customizations
        templates = templates.map do |tmplt|
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
        templates << Template.published.organisationally_visible.where(org_id: org.id,
                                                                       customization_of: nil).sort_by(&:title).to_a
      else
        # if'No Primary Research Institution' checkbox is checked,
        # only show publicly available template without customization
        # (`Template.default` belongs to `funder` and will be fetched as part of this query)
        templates << Template.published.publicly_visible.where(org_id: funder.id,
                                                               customization_of: nil).sort_by(&:title).to_a
      end
      templates.flatten
    end
    # rubocop:enable Metrics/AbcSize, Metrics/MethodLength
    # rubocop:enable Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
  end
end
