# One super admin for the default org
  # One funder Admin for the funder organization and an Org admin and User for the institutional organization
  # -------------------------------------------------------
  # TODO: Password handling must be implemented before this seed file can be used
  FUNDER_ORG_ID = ENV.fetch('FUNDER_ORG_ID').to_i
  ENGLISH_ORG_ID = ENV.fetch('ENGLISH_ORG_ID').to_i
  FRENCH_ORG_ID = ENV.fetch('FRENCH_ORG_ID').to_i

  raise StandardError, <<~ERROR
    This seed file cannot be run until password handling is implemented.
    
    The following passwords must be defined before this file can be executed:
      - USER_PASSWORD
      - SUPER_ADMIN_PASSWORD
      - ENGLISH_ADMIN_PASSWORD
      - FRENCH_ADMIN_PASSWORD
    
    Work must be done to configure these password values (likely through sealed secrets or rails credentials)
    before this seed file can be used.
  ERROR

  users = [
    {email: "dmp.super.admin@engagedri.ca",
     firstname: "Super",
     surname: "Admin",
     language_id: 1,
     password: SUPER_ADMIN_PASSWORD,
     password_confirmation: SUPER_ADMIN_PASSWORD,
     org: Org.find_by(abbreviation: "Portage"),
     language: Language.all.first,
     perms: Perm.all,
     accept_terms: true,
     api_token: Org.column_defaults['api_token'],
     confirmed_at: 5.years.ago,
     created_at: 5.years.ago,
    active:1},
    {email: "dmp.test.user.admin@engagedri.ca",
     firstname: "Test",
     surname: "User",
     password: ENGLISH_ADMIN_PASSWORD,
     password_confirmation: ENGLISH_ADMIN_PASSWORD,
     org: Org.find_by(abbreviation: 'IEO'),
     language_id: 1, # English
     perms: Perm.where.not(name: ['admin', 'add_organisations', 'change_org_affiliation', 'grant_api_to_orgs']),
     accept_terms: true,
     api_token: Org.column_defaults['api_token'],
     confirmed_at: 5.years.ago,
     created_at: 5.years.ago,
     active:1
    },
    {email: "dmp.utilisateur.test.admin@engagedri.ca",
      firstname: "Utilisateur",
      surname: "test",
      password: FRENCH_ADMIN_PASSWORD,
      password_confirmation: FRENCH_ADMIN_PASSWORD,
      language_id: 2, # French
      org: Org.find_by(abbreviation: 'OEO'),
      perms: Perm.where.not(name: ['admin', 'add_organisations', 'change_org_affiliation', 'grant_api_to_orgs']),
      accept_terms: true,
      api_token: Org.column_defaults['api_token'],
      confirmed_at: 5.years.ago,
      created_at: 5.years.ago,
      active:1
     }
  ]
  users.each{ |u| User.create(u) }
  # Some existing users for statistics. Creation times are within 12 months
  (1..20).each do |index|
    user = {
        email: "tester" + index.to_s + "@test.ca",
        firstname: Faker::Name.first_name,
        surname: Faker::Name.last_name,
        password: USER_PASSWORD,
        password_confirmation: USER_PASSWORD,
        org: Org.find_by(id: FUNDER_ORG_ID),
        language: Language.all.first,
        perms: [],
        accept_terms: true,
        api_token: Faker::Lorem.word,
        confirmed_at: rand(1...12).month.ago,
        created_at: rand(1...12).month.ago,
        active:1
    }
    User.create!(user)
  end
  (1..20).each do |index|
    user = {
        email: "tester" + (index+20).to_s + "@test.ca",
        firstname: Faker::Name.first_name,
        surname: Faker::Name.last_name,
        password: USER_PASSWORD,
        password_confirmation: USER_PASSWORD,
        org: Org.find_by(id: ENGLISH_ORG_ID),
        language: Language.all.first,
        perms: [],
        accept_terms: true,
        api_token: Faker::Lorem.word,
        confirmed_at: rand(1...12).month.ago,
        created_at: rand(1...12).month.ago,
        active:1
    }
    User.create!(user)
  end
  (1..20).each do |index|
    user = {
      email: "tester" + (index+40).to_s + "@test.ca",
      firstname: Faker::Name.first_name,
      surname: Faker::Name.last_name,
      password: USER_PASSWORD,
      password_confirmation: USER_PASSWORD,
      org: Org.find_by(id: FRENCH_ORG_ID),
      language: Language.all.last, # French
      perms: [],
      accept_terms: true,
      api_token: Faker::Lorem.word,
      confirmed_at: rand(1...12).month.ago,
      created_at: rand(1...12).month.ago,
      active:1
    }
    User.create!(user)
  end
  
  # Before enter plan data, change two template's org to the two test organization to add data to user statistics
  t1 = Template.where(:title => "Portage Template").where.not(:org_id => 8).first           
  t1.org_id = ENGLISH_ORG_ID
  t1.title += "-Test1"
  t1.save!

  t2 = Template.where(:title => "Portage Template").where.not(:org_id => 8).first     
  t2.org_id = FRENCH_ORG_ID
  t2.title += "-Test2"
  t2.save!

  