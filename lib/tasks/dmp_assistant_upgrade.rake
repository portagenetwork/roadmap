# frozen_string_literal: true

# File for DMP Assistant upgrade tasks, beginning with release 4.1.1+portage-4.2.3

# rubocop:disable Naming/VariableNumber
namespace :dmp_assistant_upgrade do
  desc 'Upgrade to DMP Assistant 4.1.1+portage-4.2.3'
  task v4_2_3: :environment do
    p '------------------------------------------------------------------------'
    p 'Executing upgrade tasks for DMP Assistant 4.1.1+portage-4.2.3'
    p 'Beginning task: Handle email confirmations for existing users'
    p '------------------------------------------------------------------------'
    handle_email_confirmations_for_existing_users
    p 'Task completed: Handle email confirmations for existing users'
    p 'Beginning task: Update `openid_connect` IdentifierScheme and its identifers'
    p '------------------------------------------------------------------------'
    if openid_scheme_and_its_identifiers_updated?
      p 'Task completed: Update `openid_connect` IdentifierScheme and its identifers'
      p 'All tasks completed successfully'
    end
  end
  # rubocop:enable Naming/VariableNumber

  private

  def handle_email_confirmations_for_existing_users
    p 'Updating :confirmable columns to nil for all users'
    p '(i.e. Setting confirmed_at, confirmation_token, and confirmation_sent_at to nil for all users)'
    p '------------------------------------------------------------------------'
    set_confirmable_cols_to_nil_for_all_users
    p '------------------------------------------------------------------------'
    p 'Updating superusers so that they are not required to confirm their email addresses'
    p '(i.e. Setting `confirmed_at = Time.now.utc` for superusers)'
    p '------------------------------------------------------------------------'
    confirm_superusers
  end

  # Setting `confirmed_at` to nil will require users to confirm their email addresses when using :confirmable
  # Setting `confirmation_token` to nil will improve the email confirmation-related UX flow for existing users
  # For more info regarding this improved UX flow, see app/controllers/concerns/email_confirmation_handler.rb
  def set_confirmable_cols_to_nil_for_all_users
    count = User.update_all(confirmed_at: nil, confirmation_token: nil, confirmation_sent_at: nil)
    p ":confirmable columns updated to nil for #{count} users"
  end

  # Sets `confirmed_at` to `Time.now.utc` for all superusers
  def confirm_superusers
    confirmed_at = Time.now.utc
    count = User.super_admins.update_all(confirmed_at: confirmed_at)
    p "Updated confirmed_at = #{confirmed_at} for #{count} superuser(s)"
  end

  # Returns an array of all perm ids that are considered super admin perms
  # (Based off of `def can_super_admin?`` in `app/models/user.rb`
  # i.e. `can_add_orgs? || can_grant_api_to_orgs? || can_change_org?` )
  def super_admin_perm_ids
    [Perm.add_orgs.id, Perm.grant_api.id, Perm.change_affiliation.id]
  end

  # Returns a boolean indicating whether the task was executed successfully
  def openid_scheme_and_its_identifiers_updated?
    identifier_scheme = IdentifierScheme.includes(:identifiers)
                                        .find_by!(name: 'openid_connect')
    old_prefix = identifier_scheme.identifier_prefix
    p "Updating identifier_prefix to '' for openid_connect IdentifierScheme"
    p '------------------------------------------------------------------------'
    begin
      ensure_correct_identifier_prefix(old_prefix)
    rescue StandardError => e
      p "Error updating IdentifierScheme: #{e.message}"
      return false
    end

    # Update identifier_prefix to '' for openid_connect
    identifier_scheme.update!(identifier_prefix: '')
    p "identifier_prefix updated from #{old_prefix} to '' for #{identifier_scheme.name} IdentifierScheme"
    p "Updating prefixed value for identifiers with multiple occurences of 'cilogon'"
    p '------------------------------------------------------------------------'
    find_and_update_identifiers(identifier_scheme, old_prefix)
    true
  end

  def ensure_correct_identifier_prefix(prefix)
    expected_prefix = 'http://cilogon.org/serverE/users/'
    error_msg = "Unexpected identifier_prefix! Expected #{expected_prefix} but got #{prefix}."
    raise error_msg unless prefix == expected_prefix
  end

  def find_and_update_identifiers(identifier_scheme, old_prefix)
    # `identifier_scheme.identifiers` == openid_connect-related identifiers
    # Get identifiers where `.value` has both the old_prefix and multiple occurences of 'cilogon'
    identifiers = identifier_scheme.identifiers.where('value ~* ?', "#{old_prefix}.+cilogon.+")
    count = identifiers.count
    p "(Found #{count} such identifiers)"
    # identifier_scheme.identifier_prefix was initially used to prefix identifier.value
    # Update by removing old_prefix from identifier.value
    identifiers.each { |identifier| identifier.update!(value: identifier.value.delete_prefix(old_prefix)) }
    p "Updated prefixed value from #{old_prefix} to '' for #{count} identifiers"
  end
end
