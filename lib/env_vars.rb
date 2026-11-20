# frozen_string_literal: true

# Load application environment variables from ENV.
# These values configure application-level settings, OmniAuth, and feature flags.
module EnvVars
  def self.load_application
    {
      default_funder_id: ENV.fetch('DEFAULT_FUNDER_ID', nil).to_i,
      dmproadmap_host: ENV.fetch('DMPROADMAP_HOST', nil),
      mailer_from: ENV.fetch('MAILER_FROM', nil),
      mailer_to: ENV.fetch('MAILER_TO', nil)
    }
  end

  def self.load_omniauth
    {
      full_host: ENV.fetch('OMNIAUTH_FULL_HOST', nil),
      orcid_client_member: ENV.fetch('ORCID_CLIENT_MEMBER', 'false') == 'true'
    }
  end

  def self.load_features
    {
      sandbox: ENV.fetch('ON_SANDBOX', 'false') == 'true'
    }
  end

  def self.load_action_mailer
    {
      host: ENV.fetch('MAILER_DEFAULT_HOST') do
        Socket.gethostname if Rails.env.local?
      end
    }
  end
end
