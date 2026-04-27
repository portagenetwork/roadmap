# frozen_string_literal: true

namespace :perms do
  desc 'Add perm for managing OAuth apps'
  task add_oauth_apps_perm: :environment do
    perm = Perm.find_or_create_by(name: 'manage_oauth_apps')

    # Grant the new permission to all super admins
    User.super_admins.each do |user|
      user.perms << perm unless user.perms.include?(perm)
    end
  end
end
