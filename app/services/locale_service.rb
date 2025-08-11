# frozen_string_literal: true

# Helpers methods for handling I18n and GetText
class LocaleService
  class << self
    # Returns the default locale/language
    def default_locale
      abbrev = Language.default.try(:abbreviation) if Language.table_exists?
      abbrev.present? ? abbrev : Rails.configuration.x.locales.default
    end

    alias default_language default_locale

    # Returns the available locales/languages
    def available_locales
      locales = Language.sorted_by_abbreviation.pluck(:abbreviation).presence if Language.table_exists?
      locales.present? ? locales : [default_locale]
    end

    alias available_languages available_locales

    # Converts the locale to the i18n format (e.g. `en-GB`)
    def to_i18n(locale:)
      join_char = Rails.configuration.x.locales.i18n_join_character
      locale = default_locale unless locale.present?
      convert(string: locale, join_char: join_char)
    end

    # Converts the locale to the i18n format (e.g. `en_GB`)
    def to_gettext(locale:)
      join_char = Rails.configuration.x.locales.gettext_join_character
      locale = default_locale unless locale.present?
      convert(string: locale, join_char: join_char)
    end

    # Localizes the given block to the recipient's preferred locale.
    # recipient may be an instance of User or Org (is able to respond to language&.abbreviation)
    def with_preferred_locale(recipient, &)
      # Fallback to the current locale, if necessary
      locale = recipient&.language&.abbreviation || I18n.locale
      I18n.with_locale(locale, &)
    end

    # Iterates over each available locale, switching to that locale,
    # and yields the locale to the given block for translation and processing.
    def with_each_available_locale
      I18n.available_locales.each do |locale|
        I18n.with_locale(locale) { yield(locale) }
      end
    end

    # Returns an array of string elements
    # The elements are all of the available translations of `text` across all available locales
    def translations_for_all_locales(text)
      return [] unless text.present?

      arr = I18n.available_locales.map { |locale| I18n.with_locale(locale) { _(text) } }
      # Remove duplicates (occurs when a locale falls back to the default translation)
      arr.uniq
    end

    private

    def convert(string:, join_char: Rails.configuration.x.locales.gettext_join_character)
      language, region = string.to_s.scan(/[a-zA-Z]{2}/)
      language.downcase! if language.present?
      region.upcase!     if region.present?
      region.present? ? "#{language}#{join_char}#{region}" : language
    end
  end
end
