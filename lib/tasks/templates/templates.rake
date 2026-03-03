# frozen_string_literal: true

namespace :templates do
  desc('Updates title + description of specific customizable UNBC templates ' \
       'to match corresponding funder (Alliance) template title + description.')
  task update_unbc_templates: :environment do
    # Dry run by default
    apply = ENV['APPLY'] == 'true'
    funder_id = Rails.application.config.default_funder_id

    # NOTE: Although `id` uniquely identifies these records, we intentionally
    # include additional constraints (name, org_id, title, published) as defensive
    # guards. This ensures the task fails loudly if run in an unexpected
    # environment or if the templates have drifted from the expected state.
    unbc_id = Org.find_by!(id: 43, name: 'University of Northern BC').id

    # Get x_funder_source and x_unbc_target templates
    # - x_funder_source: The customizable funder (Alliance) template that has the desired title + description
    # - x_unbc_target: The corresponding customizable UNBC template whose title + description are to be updated
    crdcn_funder_source = Template.find_by!(id: 3468, org_id: funder_id, published: true)
    crdcn_unbc_target_title = 'CRDCN Template for Research Data Centres and External Analysis'
    crdcn_unbc_target = Template.find_by!(id: 4248, org_id: unbc_id, title: crdcn_unbc_target_title, published: true)

    portage_funder_source = Template.find_by!(id: 3508, org_id: funder_id, published: true)
    portage_crdcn_target_title = 'Portage CRDCN Template for Accessing Data from Research Data Centres'
    portage_unbc_target = Template.find_by!(id: 3556, org_id: unbc_id, title: portage_crdcn_target_title,
                                            published: true)

    # For each pairing, ensure that x_unbc_target is a customization_of x_funder_source
    verify_customization_pair!(funder_source: crdcn_funder_source, unbc_target: crdcn_unbc_target)
    verify_customization_pair!(funder_source: portage_funder_source, unbc_target: portage_unbc_target)

    # For each pairing, use x_funder_source for the update on x_unbc_target
    update_target_template_from_source(funder_source: crdcn_funder_source, unbc_target: crdcn_unbc_target,
                                       apply: apply)
    update_target_template_from_source(funder_source: portage_funder_source, unbc_target: portage_unbc_target,
                                       apply: apply)
  end

  def verify_customization_pair!(funder_source:, unbc_target:)
    return if unbc_target.customization_of == funder_source.family_id

    raise "Template #{unbc_target.id} (customization_of=#{unbc_target.customization_of}) " \
          "is not a customization of Template #{funder_source.id} (family_id=#{funder_source.family_id})"
  end

  def update_target_template_from_source(funder_source:, unbc_target:, apply:)
    puts '-----------------------------------------------'
    puts "Updating Template #{unbc_target.id}: #{unbc_target.title.inspect} -> #{funder_source.title.inspect}"
    if apply
      # Use funder_source (Alliance template) to update title and description of unbc_target (UNBC template)
      unbc_target.update!(
        title: funder_source.title,
        description: funder_source.description
      )
      puts "Update complete. New title: #{unbc_target.title.inspect}"
    else
      puts 'Dry run: skipping update'
    end
  end
end
