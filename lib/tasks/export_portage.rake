# frozen_string_literal: true

namespace :export_production_data do
  desc 'Generate seed files'
  # The procedure can be adjusted depending on whether the task will be run in a different server first
  task build_sandbox_data: :environment do
    ActiveRecord::Base.establish_connection(Rails.env.to_s.to_sym)
    puts 'Make sure this task in running under production database instead of sandbox database.'
    puts 'seed_0 is manually generated. Skip.'
    puts 'generating seed_1.rb...'
    Rake::Task['export_production_data:seed_1_export'].execute
    puts 'generating seed_2.rb...'
    Rake::Task['export_production_data:seed_2_export'].execute
    puts 'generating seed_3.rb...'
    Rake::Task['export_production_data:seed_3_export'].execute
    puts 'seed_4 is manually generated. Skip.'
    puts 'generating seed_5.rb...'
    Rake::Task['export_production_data:seed_5_export'].execute
    puts 'seed_6 is manually generated. Skip.'
    puts 'Now switch to sandbox db environment and seed'
    puts 'Now copy seeds.rb and all files in seeds folder to sandbox server, then run bundle exec rake db:setup'
  end

  #####################################################
  ## In order to preserve the sequence of the seed file
  ## Following tasks needs to be run in sequence
  #####################################################

  # seed_1: org & question format must be created before templates and template-related components
  desc 'Export org and question format from 3.0.2 database to seeds_1.rb'

  # rubocop:disable Metrics/MethodLength
  def build_sandbox_orgs
    default_org = Org.find(Rails.application.config.default_funder_id)
    # Add one English and one French sandbox org
    updates = [
      {
        name: 'Test Organization',
        abbreviation: 'IEO',
        contact_name: 'Test User',
        contact_email: 'dmp.test.user.admin@engagedri.ca',
        language_id: 1, # English
        feedback_msg: <<~HTML
          <p>Hello %{user_name}.</p>
          <br><p>
          Your plan "%{plan_name}" has been submitted for feedback from an administrator at your organisation.
          <br>If you have questions pertaining to this action, please contact us at %{organisation_email}.
          </p>
        HTML
      },
      { name: 'Organisation de test',
        abbreviation: 'OEO',
        contact_name: 'Utilisateur test',
        contact_email: 'dmp.utilisateur.test.admin@engagedri.ca',
        language_id: 2, # French
        feedback_msg: <<~HTML
          <p>Bonjour %{user_name}.</p>
          <br><p>Votre plan "%{plan_name}" a été soumis pour commentaires d’un administrateur de votre organisation.
          <br>Si vous avez des questions concernant cette action, veuillez communiquer avec nous à %{organisation_email}.
          </p>
        HTML
      }
    ]

    test_orgs = updates.map do |attrs|
      # Use `.find_or_initialize_by` to avoid "Name must be unique" validation error
      org = Org.find_or_initialize_by(name: attrs[:name])
      org.update!(attrs.except(:name))
      org
    end

    [default_org] + test_orgs
  end
  # rubocop:enable Metrics/MethodLength

  task seed_1_export: :environment do
    file_name = 'db/seeds/sandbox/seeds_1.rb'
    FileUtils.rm_f(file_name)
    Faker::Config.random = Random.new(Org.count)
    File.open(file_name, 'a') do |f|
      excluded_keys = %w[created_at updated_at]
      orgs = build_sandbox_orgs
      orgs.each do |org|
        serialized = org.serializable_hash.delete_if { |key, _value| excluded_keys.include?(key) }
        f.puts "Org.create!(#{serialized})"
      end
      QuestionFormat.all.each do |question_formats|
        excluded_keys = %w[created_at updated_at]
        question_formats.option_based = false if question_formats.id == 7
        serialized = question_formats.serializable_hash.delete_if { |key, _value| excluded_keys.include?(key) }
        f.puts "QuestionFormat.create(#{serialized})"
      end
    end
  end

  # seed2: guidance group and theme must be created before guidance and questions (using theme)
  desc 'Export guidance group and theme format from 3.0.2 database to seeds_2.rb'
  def sandbox_guidance_groups
    orgs = Org.where(id: Rails.application.config.default_funder_id)
              .or(Org.where(name: ['Test Organization', 'Organisation de test']))
    GuidanceGroup.where(org_id: orgs.pluck(:id))
  end
  task seed_2_export: :environment do
    file_name = 'db/seeds/sandbox/seeds_2.rb'
    FileUtils.rm_f(file_name)
    excluded_keys = %w[created_at updated_at]
    File.open(file_name, 'a') do |f|
      sandbox_guidance_groups.each do |guidance_group|
        serialized = guidance_group.serializable_hash.delete_if { |key, _value| excluded_keys.include?(key) }
        f.puts "GuidanceGroup.create!(#{serialized})"
      end
      Theme.all.each do |theme|
        serialized = theme.serializable_hash.delete_if { |key, _value| excluded_keys.include?(key) }
        f.puts "Theme.create!(#{serialized})"
      end
    end
  end

  # seed3: guidance and template related components runs lastly
  desc 'Export guidance and template_related content from 3.0.2 database to seeds_3.rb'

  def sandbox_templates
    funder_templates = Template.where(org_id: Rails.application.config.default_funder_id, published: true)
    # test_org_templates are needed for db/seeds/sandbox/seeds_4.rb
    test_templates = Template.where(title: 'Alliance Template')
                             .where.not(org_id: Rails.application.config.default_funder_id)
                             .limit(2)
                             .to_a
    english_test_org = Org.find_by(name: 'Test Organization')
    french_test_org = Org.find_by(name: 'Organisation de test')
    # Assign the templates to the two test organisations
    test_templates.first.update!(org_id: english_test_org.id, title: 'Alliance Template-Test1')
    test_templates.last.update!(org_id: french_test_org.id, title: 'Alliance Template-Test2')
    funder_templates + test_templates
  end

  def sandbox_guidances
    orgs = Org.where(id: Rails.application.config.default_funder_id)
              .or(Org.where(name: ['Test Organization', 'Organisation de test']))
    guidance_groups = GuidanceGroup.where(org_id: orgs.pluck(:id))
    Guidance.where(guidance_group_id: guidance_groups.pluck(:id))
  end

  task seed_3_export: :environment do
    file_name = 'db/seeds/sandbox/seeds_3.rb'
    FileUtils.rm_f(file_name)
    excluded_keys = %w[created_at updated_at]
    File.open(file_name, 'a') do |f|
      sandbox_guidances.each do |guidance|
        guidance.theme_ids = [Theme.all.sample.id]
        serialized = guidance.serializable_hash.delete_if { |key, _value| excluded_keys.include?(key) }
        f.puts "Guidance.create(#{serialized})"
      end
      sandbox_templates.each do |template|
        # Too many version of template crashes rake, just get the published version
        serialized = template.serializable_hash.delete_if { |key, _value| excluded_keys.include?(key) }
        f.puts "Template.create!(#{serialized})"
        # create phases
        phases = Phase.where(template_id: template.id) # retrieve template old id
        phases.all.each do |phase|
          serialized = phase.serializable_hash.delete_if { |key, _value| excluded_keys.include?(key) }
          f.puts "Phase.create(#{serialized})"
          # create sections
          sections = Section.where(phase_id: phase.id)
          sections.all.each do |section|
            serialized = section.serializable_hash.delete_if { |key, _value| excluded_keys.include?(key) }
            f.puts "Section.create(#{serialized})"
            # create questions
            questions = Question.where(section_id: section.id)
            questions.all.each do |question|
              excluded_keys = %w[created_at updated_at]
              serialized = question.serializable_hash.delete_if do |key, _value|
                excluded_keys.include?(key)
              end
              f.puts "Question.create(#{serialized})"
              # create question options
              question_options = QuestionOption.where(question_id: question.id)
              question_options.all.each do |question_option|
                serialized = question_option.serializable_hash.delete_if do |key, _value|
                  excluded_keys.include?(key)
                end
                f.puts "QuestionOption.create(#{serialized})"
              end
              # create annotations
              annotations = Annotation.where(question_id: question.id)
              annotations.all.each do |annotation|
                serialized = annotation.serializable_hash.delete_if do |key, _value|
                  excluded_keys.include?(key)
                end
                f.puts "Annotation.create(#{serialized})"
              end
            end
          end
        end
      end
    end
  end
  # seed5: export all plan which org belongs to testers, this task generate the seed file that runs lastly
  desc 'Export plan content from 3.0.2 database to seeds_5.rb'
  task seed_5_export: :environment do
    file_name = 'db/seeds/sandbox/seeds_5.rb'
    FileUtils.rm_f(file_name)
    excluded_keys = %w[created_at updated_at start_date end_date]
    english_org_id = Org.find_by(abbreviation: 'IEO').id
    french_org_id = Org.find_by(abbreviation: 'OEO').id
    org_list = [Rails.application.config.default_funder_id, english_org_id, french_org_id]
    File.open(file_name, 'a') do |f|
      Plan.where(org_id: org_list).all.each_with_index do |plan, index|
        plan.title = "Test Plan #{index}"
        plan.description = Faker::Lorem.sentence
        # force a few plan to use modified template from the two test organizations for statistics
        if [20..50].include?(index) # rubocop:disable Performance/CollectionLiteralInLoop
          plan.template = Template.find(title: 'Alliance Template-Test1')
        elsif [60..90].include?(index) # rubocop:disable Performance/CollectionLiteralInLoop
          plan.template = Template.find(title: 'Alliance Template-Test2')
        end
        serialized = plan.serializable_hash.delete_if { |key, _value| excluded_keys.include?(key) }
        f.puts "Plan.create(#{serialized})"
        # import related roles
        Role.where(plan_id: plan.id).all.each do |role|
          role.user_id = if plan.org_id == Rails.application.config.default_funder_id # change all user id to 1
                           1
                         elsif plan.org_id == english_org_id # change all user id to 2
                           2
                         else # change all user id to 3
                           3
                         end
          serialized = role.serializable_hash.delete_if { |key, _value| excluded_keys.include?(key) }
          f.puts "Role.create(#{serialized})"
        end
      end
    end
  end
end
