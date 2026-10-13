# frozen_string_literal: true

namespace :doorkeeper do
  desc 'Ensure internal OAuth application exists'
  task ensure_internal_app: :environment do
    app = Doorkeeper::Application.find_or_create_by!(
      name: Rails.application.config.x.application.internal_oauth_app_name
    ) do |a|
      a.scopes = 'read'
      a.confidential = true
    end

    puts "Internal OAuth app ready (id=#{app.id}, uid=#{app.uid})"
  end

  desc 'Migrate legacy read/write scopes on OAuth applications and unrevoked access tokens to v2_read/v2_write'
  task migrate_legacy_scopes: :environment do
    counts = Api::V2::LegacyScopeMigrationService.new.call
    counts.each do |type, count|
      puts "#{type.to_s.humanize}: #{count} migrated"
    end
  end

  desc 'Revoke access tokens (and their refresh tokens) that expired over 3 months ago'
  task revoke_stale_tokens: :environment do
    puts "Revoked #{Api::StaleAccessTokenRevoker.new.call} stale access token(s)"
  end

  desc 'Revoke stale tokens, then run the standard Doorkeeper cleanup'
  task stale_cleanup: ['doorkeeper:revoke_stale_tokens', 'doorkeeper:db:cleanup']
end
