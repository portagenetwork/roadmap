# frozen_string_literal: true

namespace :orgs do
  desc 'Updates DB and Creates CSV with Org-related ROR/Fundref data'
  task update_ror_data: :environment do
    Orgs::UpdateRorService.run
  end

  # IMPORTANT:
  # Recommended execution order for org cleanup tasks:
  #
  # 1. Take a full database dump for audit and rollback purposes.
  #
  # 2. Run cleanup tasks that may free additional orphan orgs **before** deleting orphans:
  #    - delete_junk_trackers (does NOT support DRY_RUN)
  #    - cleanup_unmanaged_orgs_with_users (supports DRY_RUN)
  #    - cleanup_junk_funders (supports DRY_RUN)
  #
  #    The tasks that support DRY_RUN output counts of the changes they would make.
  #    These outputs can be compared against the local DB dump to verify expected
  #    changes before performing any mutations.
  #
  # 3. Run delete_orphan_orgs LAST.
  #    - Supports DRY_RUN and outputs a CSV of to-be-deleted orgs (orphan_orgs.csv).
  #    - Performs irreversible deletes; only run after other cleanup tasks are complete.
  #    - Outputs a CSV after deletion completes (deleted_orphan_orgs.csv).

  desc 'Deletes "junk trackers" from the DB (i.e. Tracker.where(code: ""))'
  task delete_junk_trackers: :environment do
    Orgs::DeleteJunkTrackersService.run
  end

  desc 'Cleans up unmanaged orgs having 1 or more users.
        For each such org:
        - Reassign associated users and plans to the "default org"'
  task cleanup_unmanaged_orgs_with_users: :environment do
    # Passing `DRY_RUN=true` bypasses db updates,
    # and simply updates how many unmanaged_orgs with users were found
    # as well as how many users and plans will be reassigned to the default org.
    dry_run = ENV['DRY_RUN'] == 'true'
    Orgs::CleanupUnmanagedOrgsWithUsersService.run(dry_run: dry_run)
  end

  desc 'Finds "junk funders" and sets `plan.funder_id = nil` for their associated plans
        - Junk funders are orgs meeting the following criteria:
          1) Have `org.id == plan.funder_id` as their only association
          2) Have a "junk" name (see JUNK_FUNDER_NAMES in CleanupJunkFundersService)'
  task cleanup_junk_funders: :environment do
    # Passing `DRY_RUN=true` bypasses db updates,
    # and simply updates how many junk funders were found as well as
    # how many plans will be updated by the task.
    dry_run = ENV['DRY_RUN'] == 'true'
    Orgs::CleanupJunkFundersService.run(dry_run: dry_run)
  end

  desc 'Deletes all "orphan" orgs from the db.
        - (Orphan = org with no entries in any `has_many` or HABTM associations.)'
  task delete_orphan_orgs: :environment do
    # Passing `DRY_RUN=true` bypasses destruction,
    # and outputs a csv of which orgs this task will delete.
    dry_run = ENV['DRY_RUN'] == 'true'
    Orgs::DeleteOrphanOrgsService.run(dry_run: dry_run)
  end
end
