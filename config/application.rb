# frozen_string_literal: true

require 'rails/all'
require 'recaptcha/rails'
require 'csv'
require 'nulldb/rails'
require_relative "boot"
require_relative '../lib/sealed_secrets'
require_relative '../lib/env_vars'

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module DMPRoadmap
  # DMP Assistant application
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 7.1

    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration can go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded after loading
    # the framework and any gems in your application.

    # --------------------------------- #
    # OVERRIDES TO DEFAULT RAILS CONFIG #
    # --------------------------------- #
    config.autoload_lib(ignore: %w[tasks])

    # CVE-2022-32224: add some compatibility with YAML.safe_load
    # Rails 5,6,7 are using YAML.safe_load as the default YAML deserializer
    config.active_record.yaml_column_permitted_classes = [ActiveSupport::HashWithIndifferentAccess, Symbol, Date, Time]

    # Have Zeitwerk skip generators because the generator templates are
    # incompatible with the Rails module/class naming conventions
    Rails.autoloaders.main.ignore(config.root.join('lib/generators'))

    # HTML tags that are allowed to pass through `sanitize`.
    config.action_view.sanitized_allowed_tags = %w[
      p br strong em a table thead tbody tr td th tfoot caption ul ol li
    ]

    # Configure sensitive parameters which will be filtered from the log file.
    config.filter_parameters += [:password]

    # Enable escaping HTML in JSON.
    config.active_support.escape_html_entities_in_json = true

    # Allow controllers to access view helpers
    # TODO: We should see what methods specifically are used by the controllers
    #       and include them specifically in the controllers. We should also consider
    #       moving our helper methods into Presenters if it makes sense
    config.action_controller.include_all_helpers = true

    # Action mailer settings
    action_mailer_config = EnvVars.load_action_mailer
    config.action_mailer.default_url_options = {
      host: action_mailer_config[:host]
    }

    # Application-level settings
    config.x.application = ActiveSupport::OrderedOptions.new.merge!(EnvVars.load_application)

    # OmniAuth settings
    config.x.omniauth = ActiveSupport::OrderedOptions.new.merge!(EnvVars.load_omniauth)

    # Feature flags
    config.x.features = ActiveSupport::OrderedOptions.new.merge!(EnvVars.load_features)

    # Store the sealed secrets in config.x.sealed_secrets, making them accessible
    # throughout the application (e.g. config.x.sealed_secrets.database_url).
    config.x.sealed_secrets = ActiveSupport::OrderedOptions.new.merge!(SealedSecrets.load)

    # Enable shibboleth as an alternative authentication method
    # Requires server configuration and omniauth shibboleth provider configuration
    # See config/initializers/devise.rb
    config.shibboleth_enabled = false
    config.openid_connect_enabled = true

    # Relative path to Shibboleth SSO Logout
    config.shibboleth_login = '/Shibboleth.sso/Login'
    config.shibboleth_logout_url = '/Shibboleth.sso/Logout?return='

    # If this value is set to true your users will be presented with a list of orgs that have a
    # shibboleth identifier in the orgs_identifiers table. If it is set to false (default), the user
    # will be driven out to your federation's discovery service
    #
    # A super admin will also be able to associate orgs with their shibboleth entityIds if this is set to true
    config.shibboleth_use_filtered_discovery_service = false

    # Active Record will no longer suppress errors raised in after_rollback or after_commit
    # in the next version. Devise appears to be using those callbacks.
    # To accept the new behaviour use 'true' otherwise use 'false'
    # config.active_record.raise_in_transactional_callbacks = true

    # Load Branded terminology (e.g. organization name, application name, etc.)
    config.branding = config_for(:branding).deep_symbolize_keys if File.exist?(Rails.root.join('config/branding.yml'))

    # The default visibility setting for new plans
    #   organisationally_visible  - Any member of the user's org can view, export and duplicate the plan
    #   publicly_visibile         - (NOT advisable because plans will show up in Public DMPs page by default)
    #   is_test                   - (NOT advisable because test plans are excluded from statistics)
    #   privately_visible         - Only the owner and people they invite can access the plan
    config.default_plan_visibility = 'privately_visible'

    # The percentage of answered questions needed to enable the plan visibility section of the Share plan page
    config.default_plan_percentage_answered = 0

    # DMP Assistant works with the assumption that the user will not use a
    # specific funder. The view for choosing a funder when creating a plan
    # removed the option for selecting a funder. A funder is needed to show the
    # customized templates.
    # NOTE: This is now configured via config.x.application.default_funder_id

    # apply application styling to doorkeeper views
    config.to_prepare do
      Doorkeeper::ApplicationsController.layout "application"
      Doorkeeper::AuthorizationsController.layout "application"
      Doorkeeper::AuthorizedApplicationsController.layout "application"
    end
  end
end
