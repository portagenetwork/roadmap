# frozen_string_literal: true

module Orgs
  # Invoked by the `orgs:cleanup_unmanaged_orgs_with_users` Rake task.
  # Cleanup service for unmanaged orgs having 1 or more users.
  # For each such org:
  # - Reassign associated users and plans to the "default org"
  # NOTE: Org deletion is handled separately by the `delete_orphan_orgs` task
  module CleanupUnmanagedOrgsWithUsersService
    extend self

    Result = Struct.new(
      :processed_orgs_count,
      :reassigned_users_count,
      :reassigned_plans_count,
      keyword_init: true
    )

    def run(dry_run: false)
      result = initial_result

      default_org = fetch_default_org
      orgs_to_process = unmanaged_orgs_with_users

      if dry_run
        handle_dry_run(orgs: orgs_to_process, result: result)
        return
      end

      orgs_to_process.find_each do |org|
        result.processed_orgs_count += 1
        Org.transaction do
          reassign_users_to_default_org(org, default_org, result)
          reassign_plans_to_default_org(org, default_org, result)
        end
      end

      print_summary(result)
    end

    private

    def initial_result
      Result.new(
        processed_orgs_count: 0,
        reassigned_users_count: 0,
        reassigned_plans_count: 0
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

    def handle_dry_run(orgs:, result:)
      handle_dry_run_result(orgs: orgs, result: result)
      print_dry_run_summary(result)
    end

    def handle_dry_run_result(orgs:, result:)
      org_ids = orgs.pluck(:id)
      result.processed_orgs_count = org_ids.size
      result.reassigned_users_count = User.where(org_id: org_ids).count
      result.reassigned_plans_count = Plan.where(org_id: org_ids).count
    end

    def print_dry_run_summary(result)
      puts <<~MSG
        ----- DRY RUN Summary -----
        Unmanaged orgs with users:  #{result.processed_orgs_count}
        Users to be reassigned:     #{result.reassigned_users_count}
        Plans to be reassigned:     #{result.reassigned_plans_count}
      MSG
    end

    def print_summary(result)
      puts <<~MSG
        ----- Summary -----
        Unmanaged orgs processed: #{result.processed_orgs_count}
        Users reassigned:         #{result.reassigned_users_count}
        Plans reassigned:         #{result.reassigned_plans_count}
      MSG
    end
  end
end
