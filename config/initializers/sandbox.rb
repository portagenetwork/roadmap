# frozen_string_literal: true

# All deployed environments use RAILS_ENV=production and config/environments/production.rb.
# Here, we override certain settings based on feature flags (e.g., on_sandbox).

# Prevent actual email delivery in sandbox
# Note: Using secrets directly here to avoid autoloading FeatureFlagHelper during initialization
Rails.application.config.action_mailer.delivery_method = :test if Rails.application.secrets.on_sandbox.to_s == 'true'
