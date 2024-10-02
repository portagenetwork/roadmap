# frozen_string_literal: true

# File for DMP Assistant upgrade tasks, beginning with release 4.1.1+portage-4.2.3

namespace :dmp_assistant_upgrade do
  desc 'Upgrade to DMP Assistant 4.1.1+portage-4.2.3'
  task v4_2_3: :environment do
    p 'Executing upgrade tasks for DMP Assistant 4.1.1+portage-4.2.3'
    p 'Beginning task 1: Handle email confirmation statuses of existing users'
    p '------------------------------------------------------------------------'
    handle_email_confirmation_statuses
  end

  private

  def handle_email_confirmation_statuses
    p 'Beginning task 1a: Handle email confirmation statuses for users with outstanding invitations'
    p '------------------------------------------------------------------------'
    handle_unconfirmed_users_with_outstanding_invitations
    p 'Beginning task 1b: Handle email confirmation statuses of user accounts created via SSO'
    p '------------------------------------------------------------------------'
    handle_unconfirmed_users_created_via_sso
    p 'Task 1 completed successfully'
  end

  # Fetches users where 'confirmed_at IS NULL AND confirmation_token IS NOT NULL'
  # Sets confirmation_token = NULL AND confirmation_sent_at = NULL for the aforementioned users
  # `confirmation_sent_at` dates corresponding to these particular users are quite old (the most recent is 2021-02-22 15:18:24)
  # With respect to confirming their email addresses, these db changes will improve the UX flow for these users
  # (For more insight regarding this improved UX flow,
  # refer to def handle_missing_confirmation_instructions(user) in app/controllers/sessions_controller.rb)
  def handle_unconfirmed_users_with_outstanding_invitations
    p 'Querying for users with unconfirmed emails AND outstanding/outdated confirmation invitations'
    expected_count = 6413
    p "Expecting to find #{expected_count} users"
    p '------------------------------------------------------------------------'
    unconfirmed_users = User.where(confirmed_at: nil).where.not(confirmation_token: nil)
    count = unconfirmed_users.count
    abort "#{count} users found. Aborting the upgrade task." if count != expected_count

    p "#{count} users found"
    p '------------------------------------------------------------------------'
    p 'Setting confirmation_token = NULL AND confirmation_sent_at = NULL for all of these unconfirmed users'
    p '------------------------------------------------------------------------'
    unconfirmed_users.update_all(confirmation_token: nil, confirmation_sent_at: nil)
    p '------------------------------------------------------------------------'
    p 'Task 1a completed successfully'
  end

  # Fetches users "created via SSO" and updates confirmed_at = Time.now for those users
  # We define a user as "created via SSO" if BOTH of the following conditions are true:
  # 1. An Identifier corresponding to the "openid_connect" IdentifierScheme exists for the user
  # 2. For the identifier and corresponding user found in 1.,
  #    identifier.created_at AND user.created_at are within 1 second of each other
  def handle_unconfirmed_users_created_via_sso
    openid_connect_scheme = IdentifierScheme.find_by(name: 'openid_connect')
    p 'Querying for all users created via SSO'
    p '------------------------------------------------------------------------'
    sql_where = 'ABS(EXTRACT(EPOCH FROM users.created_at) - EXTRACT(EPOCH FROM identifiers.created_at)) <= 1'
    users_created_via_sso = User.joins(:identifiers)
                                .where(identifiers: { identifier_scheme_id: openid_connect_scheme.id })
                                .where(sql_where)
                                .distinct
    p "Found #{users_created_via_sso.count} users created via SSO"
    confirmed_at = Time.now
    p "Updating these users as confirmed with 'confirmed_at = #{confirmed_at}'"
    p '------------------------------------------------------------------------'
    users_created_via_sso.update_all(confirmed_at: confirmed_at)
    p 'Task 1b completed successfully'
  end
end
