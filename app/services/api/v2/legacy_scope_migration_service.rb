# frozen_string_literal: true

module Api
  module V2
    # Migrates legacy Doorkeeper `read` / `write` scopes to their v2 equivalents
    # on OAuth applications and unrevoked access tokens:
    # - `read`  => `v2_read`
    # - `write` => `v2_read v2_write` (write implies read)
    # Other scopes are preserved. Revoked tokens are left untouched since they
    # can neither be used nor refreshed.
    #
    # Returns:
    # - A Hash with the number of records updated, e.g. { applications: 2, access_tokens: 5 }
    class LegacyScopeMigrationService
      V2_READ = DoorkeeperApiHelper::V2_READ_SCOPE
      V2_WRITE = DoorkeeperApiHelper::V2_WRITE_SCOPE

      def call
        {
          applications: migrate(Doorkeeper::Application.all),
          access_tokens: migrate(Doorkeeper::AccessToken.where(revoked_at: nil))
        }
      end

      private

      def migrate(relation)
        count = 0
        relation.find_each do |record|
          updated = migrated_scopes(record.scopes)
          next if updated.nil?

          record.update_column(:scopes, updated.to_s)
          count += 1
        end
        count
      end

      # Returns the migrated Scopes, or nil when there is nothing to migrate
      def migrated_scopes(current)
        return unless current.exists?('read') || current.exists?('write')

        # Scopes#add de-duplicates (it calls uniq! internally), so overlapping
        # mappings are safe: 'read write' becomes 'v2_read v2_write', not
        # 'v2_read v2_read v2_write'.
        updated = Doorkeeper::OAuth::Scopes.new
        current.each do |scope|
          case scope
          when 'read' then updated.add(V2_READ)
          when 'write' then updated.add(V2_READ, V2_WRITE)
          else updated.add(scope)
          end
        end
        updated
      end
    end
  end
end
