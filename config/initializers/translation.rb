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

# Setup languages
def default_locale
  DEFAULT_LOCALE
end

def available_locales
  SUPPORTED_LOCALES
end

I18n.available_locales = SUPPORTED_LOCALES

I18n.default_locale = DEFAULT_LOCALE
