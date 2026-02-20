# frozen_string_literal: true

namespace :data_migration do
  desc 'Updates nil `user.language_id` values using `user.org.language_id`'
  task update_nil_user_language_ids_from_orgs: :environment do
    users_to_be_updated = query_nil_language_users_for_update
    # Exit rake task if users_to_be_updated is empty
    ensure_update_needed(users_to_be_updated)
    # user_ids will be used to later output the updated results
    user_ids = users_to_be_updated.pluck(:id)
    # Perform the update
    update_users(users_to_be_updated)
    # Output a breakdown of the updated results
    output_update_results(user_ids)
    # Output if any users still have nil language_id after update
    output_remaining_nil_language_users
    puts 'Rake task completed.'
  end

  private

  # Queries users that will be updated within this rake task
  # The following nil_language users WILL NOT be updated within this rake task:
  # - users where `user.org == nil` or `user.org.language_id == nil`
  # (However, no such users should exist)
  def query_nil_language_users_for_update
    query_nil_language_users.joins(:org)
                            .where.not(orgs: { language_id: nil })
  end

  def query_nil_language_users
    User.where(language_id: nil)
  end

  # Exits rake task if there is no update to perform
  # Otherwise, outputs number of users to be updated
  def ensure_update_needed(users_to_be_updated)
    if users_to_be_updated.empty?
      print_and_warn('No users to be updated. Exiting rake task.')
      exit(0)
    else
      puts "Found #{users_to_be_updated.count} users to update."
    end
  end

  # Performs a single bulk update on users_to_be_updated
  def update_users(users_to_be_updated)
    puts 'Proceeding to use `user.org.language_id` to update each nil `user.language_id`'
    puts '------------------------------------------------------------------------'

    # Subquery for update_all() action
    # Fetches `user.org.language_id` for all users in `users_to_be_updated`
    subquery = Org.where('orgs.id = users.org_id').select(:language_id).limit(1)

    # Batch update `users_to_be_updated` with `user.org.language_id` values from subquery
    users_to_be_updated.update_all("language_id = (#{subquery.to_sql})")

    puts 'Update complete.'
  end

  # Outputs a breakdown of the updated language_id counts
  def output_update_results(user_ids)
    language_id_counts = User.where(id: user_ids)
                             .group(:language_id)
                             .count

    puts 'Summary of language_id counts for updated users:'

    language_id_counts.each do |language_id, count|
      puts "language_id: #{language_id}, count: #{count}"
    end

    puts "Total count: #{language_id_counts.values.sum}"
  end

  def output_remaining_nil_language_users
    # Query remaining users with nil language_id
    # Now we are using query_nil_language_users (not query_nil_language_users_for_update)
    remaining_users = query_nil_language_users
    if remaining_users.exists?
      # NOTE: Any remaining nil language_id users will be addressed in the SetLanguageIdNotNullOnUsers migration
      print_and_warn("#{remaining_users.count} users still have a nil language_id.")
    else
      puts 'Successfully updated language_id for all users (i.e. All users now have a non-nil language_id value).'
    end
  end

  # Message is printed to console and logs a warning
  def print_and_warn(message)
    puts message
    Rails.logger.warn(message)
  end
end
