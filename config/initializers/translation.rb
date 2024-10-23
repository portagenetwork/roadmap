# frozen_string_literal: true

# New with Rails 6+, we need to define the list of locales outside the context of
# the Database since thiss runs during startup. Trying to access the DB causes
# issues with autoloading; 'DEPRECATION WARNING: Initialization autoloaded the constants ... Language'
#
# Note that the entries here must have a corresponding directory in config/locale, a
# YAML file in config/locales and should also have an entry in the DB's languages table
SUPPORTED_LOCALES = %w[en-CA fr-CA].freeze
# You can define a subset of the locales for your instance's version of Translation.io if applicable
# CLIENT_LOCALES = %w[de en-CA en-GB en-US es fi fr-CA fr-FR pt-BR sv-FI tr-TR].freeze
DEFAULT_LOCALE = 'en-CA'

# # Control ignored source paths
# # Note, all prefixes of the directory you want to translate must be defined here
def ignore_paths
  Dir['**/'] - Dir['app/**/']
end

TranslationIO.configure do |config|
  config.api_key        = Rails.application.secrets.translation_io_api_key
  config.source_locale  = 'en'
  config.target_locales = SUPPORTED_LOCALES
  config.ignored_source_paths = ignore_paths
  config.disable_yaml         = true

  # Uncomment this if you don't want to use gettext
  # config.disable_gettext = true

  # Uncomment this if you already use gettext or fast_gettext
  config.locales_path = File.join('config', 'locale')

  unless Rails.env.in?(%w[test development uat])
    config.db_fields = {
      'Theme' => %w[title description],
      'QuestionFormat' => %w[title description],
      'Template' => %w[title description],
      'Phase' => %w[title description],
      'Section' => %w[title description],
      'Question' => %w[text default_value],
      'Annotation' => ['text'],
      'ResearchDomain' => ['label'],
      'QuestionOption' => ['text']
    }
  end
  # Find other useful usage information here:
  # https://github.com/translation/rails#readme
end

I18n.enforce_available_locales = false
I18n.default_locale = :'en-CA'

# # Here we define the translation domains for the Roadmap application, `app` will
# # contain translations from the open-source repository and ignore the contents
# # of the `app/views/branded` directory.  The `client` domain will
# #
# # When running the application, the `app` domain should be specified in your environment.
# # the `app` domain will be searched first, falling back to `client`
# #
# # When generating the translations, the rake:tasks will need to be run with each
# # domain specified in order to generate both sets of translation keys.
# if !ENV['DOMAIN'] || ENV['DOMAIN'] == 'app'
#   TranslationIO.configure do |config|
#     config.api_key              = ENV.fetch('TRANSLATION_API_ROADMAP', nil)
#     config.source_locale        = 'en'
#     config.target_locales       = SUPPORTED_LOCALES
#     config.text_domain          = 'app'
#     config.bound_text_domains   = %w[app client]
#     config.ignored_source_paths = ['app/views/branded/', 'node_modules/']
#     config.locales_path         = Rails.root.join('config', 'locale')
#   end
# elsif ENV['DOMAIN'] == 'client'
#   TranslationIO.configure do |config|
#     config.api_key              = ENV.fetch('TRANSLATION_API_CLIENT', nil)
#     config.source_locale        = 'en'
#     config.target_locales       = CLIENT_LOCALES
#     config.text_domain          = 'client'
#     config.bound_text_domains = ['client']
#     config.ignored_source_paths = ignore_paths
#     config.disable_yaml         = true
#     config.locales_path         = Rails.root.join('config', 'locale')
#   end
# end

# # Setup languages
#
# table = ActiveRecord::Base.connection.table_exists?("languages") rescue false
# # if table
#   def default_locale
#     Language.default.try(:abbreviation) || "en-GB"
#   end

#   def available_locales
#     Language.sorted_by_abbreviation.pluck(:abbreviation).presence || [default_locale]
#   end

#   I18n.available_locales = Language.all.pluck(:abbreviation)

#   I18n.default_locale = Language.default.try(:abbreviation) || "en-GB"
# else
#   def default_locale
#     Rails.application.config.i18n.available_locales.first || "en-GB"
#   end

#   def available_locales
#     Rails.application.config.i18n.available_locales = %w[en-GB en-US]
#   end

#   I18n.available_locales = ["en-GB"]

#   I18n.default_locale = "en-GB"
# end
# Setup languages
def default_locale
  DEFAULT_LOCALE
end

def available_locales
  SUPPORTED_LOCALES
end

I18n.available_locales = SUPPORTED_LOCALES

I18n.default_locale = DEFAULT_LOCALE
