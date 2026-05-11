# frozen_string_literal: true

# One super admin for the default org
# One funder Admin for the funder organization and an Org admin and User for the institutional organization
# -------------------------------------------------------
# Admins are created 5 years ago
pwd = Rails.application.secrets.user_password.to_s # pwd for regular user
default_org = Org.find(Rails.application.config.default_funder_id)
english_test_org = Org.find_by!(abbreviation: 'IEO')
french_test_org = Org.find_by!(abbreviation: 'OEO')
english = Language.find_by!(abbreviation: 'en-CA')
french = Language.find_by!(abbreviation: 'fr-CA')

admin_users = [
  { email: 'dmp.super.admin@engagedri.ca',
    firstname: 'Super',
    surname: 'Admin',
    password: pwd,
    password_confirmation: pwd,
    org: default_org,
    language: english,
    perms: Perm.all,
    accept_terms: true,
    api_token: Org.column_defaults['api_token'],
    confirmed_at: 5.years.ago,
    created_at: 5.years.ago,
    active: 1 },
  { email: 'dmp.test.user.admin@engagedri.ca',
    firstname: 'Test',
    surname: 'User',
    password: pwd,
    password_confirmation: pwd,
    org: english_test_org,
    language: english,
    perms: Perm.where.not(name: %w[admin add_organisations change_org_affiliation grant_api_to_orgs]),
    accept_terms: true,
    api_token: Org.column_defaults['api_token'],
    confirmed_at: 5.years.ago,
    created_at: 5.years.ago,
    active: 1 },
  { email: 'dmp.utilisateur.test.admin@engagedri.ca',
    firstname: 'Utilisateur',
    surname: 'test',
    password: pwd,
    password_confirmation: pwd,
    language: french,
    org: french_test_org,
    perms: Perm.where.not(name: %w[admin add_organisations change_org_affiliation grant_api_to_orgs]),
    accept_terms: true,
    api_token: Org.column_defaults['api_token'],
    confirmed_at: 5.years.ago,
    created_at: 5.years.ago,
    active: 1 }
]
admin_users.each { |u| User.create(u) }

# Some existing users for statistics. Creation times are within 12 months
user_groups = [{ org: default_org,      language: english },
               { org: english_test_org, language: english },
               { org: french_test_org,  language: french }]

# Create 60 users (20 for each user_group)
user_groups.each_with_index do |group, group_index|
  (1..20).each do |i|
    # index is unique for each user (1 thru 60)
    index = i + (20 * group_index)
    firstname = "tester#{index}"
    user = {
      email: "#{firstname}@test.ca",
      firstname: firstname,
      surname: 'Test',
      password: pwd,
      password_confirmation: pwd,
      org: group[:org],
      language: group[:language],
      perms: [],
      accept_terms: true,
      confirmed_at: rand(1...12).month.ago,
      created_at: rand(1...12).month.ago,
      active: 1
    }
    User.create!(user)
  end
end
