# frozen_string_literal: true

module Orgs
  # Invoked by the `orgs:cleanup_unmanaged_orgs_with_users` Rake task.
  # Cleanup service for unmanaged orgs having 1 or more users.
  # For each such org:
  # - Reassign associated users and plans to the "default org"
  # - Attempt deletion of the org
  module CleanupUnmanagedOrgsWithUsersService
    extend self

    Result = Struct.new(
      :processed_orgs_count,
      :reassigned_users_count,
      :reassigned_plans_count,
      :deleted_orgs_count,
      :failed_deletions_count,
      keyword_init: true
    )

    def run
      result = initial_result

      default_org = fetch_default_org

      unmanaged_orgs_with_users.find_each do |org|
        result.processed_orgs_count += 1
        Org.transaction do
          reassign_users_to_default_org(org, default_org, result)
          reassign_plans_to_default_org(org, default_org, result)
        end
        # Don't rollback org.users + org.plans reassignment if the org cannot be deleted
        handle_org_deletion(org, result)
      end

      print_summary(result)
    end

    private

    def initial_result
      Result.new(
        processed_orgs_count: 0,
        reassigned_users_count: 0,
        reassigned_plans_count: 0,
        deleted_orgs_count: 0,
        failed_deletions_count: 0
      )
    end

    def fetch_default_org
      default_org = Org.find(Rails.application.config.default_funder_id)
      puts '----------------------------------------------------------------------------------------------'
      puts "Using Org with id: '#{default_org.id}', name: '#{default_org.name}' for users/plans reassignment."
      default_org
    end

    def unmanaged_orgs_with_users
      # Fetch unmanaged orgs that have one or more users
      orgs = Org.unmanaged.joins(:users).distinct
      puts "Found #{orgs.count} unmanaged org(s) with users to process."
      orgs
    end

    def reassign_users_to_default_org(org, default_org, result)
      reassigned_count = org.users.update_all(org_id: default_org.id)
      result.reassigned_users_count += reassigned_count
      puts "✅ Reassigned #{reassigned_count} user(s) from '#{org.name}'."
    end

    def reassign_plans_to_default_org(org, default_org, result)
      reassigned_count = org.plans.update_all(org_id: default_org.id)
      result.reassigned_plans_count += reassigned_count
      puts "✅ Reassigned #{reassigned_count} plan(s) from '#{org.name}'."
    end

    def handle_org_deletion(org, result)
      if org.destroy
        increment_successful_org_deletions(org, result)
      else
        msg = org.errors.full_messages.presence || ["Unknown deletion error (org inspect: #{org.inspect})"]
        increment_failed_org_deletions(org, result, msg)
      end
    rescue StandardError => e
      increment_failed_org_deletions(org, result, ["Exception: #{e.message}"])
    end

    def increment_successful_org_deletions(org, result)
      result.deleted_orgs_count += 1
      puts "✅ Deleted unmanaged org: #{org.id} - #{org.name}"
    end

    def increment_failed_org_deletions(org, result, messages)
      result.failed_deletions_count += 1
      puts "⚠️ Failed to delete unmanaged org: #{org.id} - #{org.name}: #{messages.join(', ')}"
    end

    def print_summary(result)
      puts <<~MSG
        ----- Summary -----
        Unmanaged orgs processed: #{result.processed_orgs_count}
        Users reassigned: #{result.reassigned_users_count}
        Plans reassigned: #{result.reassigned_plans_count}
        Successfully deleted orgs: #{result.deleted_orgs_count}
        Failed org deletions: #{result.failed_deletions_count}
      MSG
    end
  end
end
