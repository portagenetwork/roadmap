# frozen_string_literal: true

namespace :orgs do
  desc 'Updates DB and Creates CSV with Org-related ROR/Fundref data'
  task update_ror_data: :environment do
    Orgs::UpdateRorService.run
  end

  desc 'Cleans up unmanaged orgs having 1 or more users.
        For each such org:
        - Reassign associated users and plans to the "default org"'
  task cleanup_unmanaged_orgs_with_users: :environment do
    Orgs::CleanupUnmanagedOrgsWithUsersService.run
  end
end
