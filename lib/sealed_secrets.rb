# frozen_string_literal: true

# Load sealed secrets from environment variables.
# These values are injected as environment variables from Kubernetes sealed-secret objects.
#
# The corresponding sealed secret definitions are managed in the roadmap-deploy repository:
# https://github.com/portagenetwork/roadmap-deploy
#
# To add or update secrets, modify the sealed secret files in roadmap-deploy and reseal them
# for your cluster using kubeseal.
module SealedSecrets
  def self.load
    {
      # db-sealed-secret.yaml
      database_url: ENV.fetch('DATABASE_URL', nil),
      # devise-sealed-secret.yaml
      devise_pepper: ENV.fetch('DEVISE_PEPPER', nil),
      devise_secret_key: ENV.fetch('DEVISE_SECRET_KEY', nil),
      secret_key_base: ENV.fetch('SECRET_KEY_BASE', nil),
      # integrations-sealed-secret.yaml
      cilogon_client_id: ENV.fetch('CILOGON_CLIENT_ID', nil),
      cilogon_secret_key: ENV.fetch('CILOGON_SECRET_KEY', nil),
      dragonfly_secret: ENV.fetch('DRAGONFLY_SECRET', nil),
      google_analytics_token: ENV.fetch('GOOGLE_ANALYTICS_TOKEN', nil),
      orcid_client_id: ENV.fetch('ORCID_CLIENT_ID', nil),
      orcid_client_secret: ENV.fetch('ORCID_CLIENT_SECRET', nil),
      recaptcha_secret_key: ENV.fetch('RECAPTCHA_SECRET_KEY', nil),
      recaptcha_site_key: ENV.fetch('RECAPTCHA_SITE_KEY', nil),
      rollbar_access_token: ENV.fetch('ROLLBAR_ACCESS_TOKEN', nil),
      smtp_password: ENV.fetch('SMTP_PASSWORD', nil),
      smtp_user_name: ENV.fetch('SMTP_USER_NAME', nil),
      translation_io_api_key: ENV.fetch('TRANSLATION_IO_API_KEY', nil)
    }
  end
end
