# frozen_string_literal: true

require 'rails_helper'

RSpec.describe LocaleService do
  before(:each) do
    Language.destroy_all
    @default = Language.default || create(:language, abbreviation: 'loc-svc', default_language: true)
    Rails.configuration.x.locales.default = @default.abbreviation
    Rails.configuration.x.locales.gettext_join_character = '_'
    Rails.configuration.x.locales.i18n_join_character = '-'
  end

  describe '#default_locale' do
    it 'returns the Language defined as the default in the database' do
      Language.update_all(default_language: false)
      create(:language, abbreviation: 'zz-TP', default_language: true)
      expect(described_class.default_locale).to eql('zz-TP')
    end
    it 'returns the default language defined in dmproadmap.rb initializer' do
      Language.destroy_all
      expect(described_class.default_locale).to eql(@default.abbreviation)
    end
  end

  describe '#available_locales' do
    it 'returns the abbreviations of all Languages in the database' do
      create(:language, abbreviation: 'avail-loc')
      expected = Language.all.order(:abbreviation).pluck(:abbreviation)
      expect(described_class.available_locales).to eql(expected)
    end
    it 'returns the default language if no Languages are in the database' do
      Language.destroy_all
      expect(described_class.available_locales).to eql([@default.abbreviation])
    end
  end

  describe '#to_i18n(locale:)' do
    it 'uses the default_locale if no locale is specified' do
      expect(described_class.to_i18n(locale: nil)).to eql(@default.abbreviation)
    end
    it 'converts the locale to i18n format' do
      expect(described_class.to_i18n(locale: 'en-GB')).to eql('en-GB')
      expect(described_class.to_i18n(locale: 'en_GB')).to eql('en-GB')
      expect(described_class.to_i18n(locale: 'en|GB')).to eql('en-GB')
    end
  end

  describe '#to_gettext(locale:)' do
    it 'uses the default_locale if no locale is specified' do
      expect(described_class.to_gettext(locale: nil)).to eql(LocaleService.to_gettext(locale: @default.abbreviation))
    end
    it 'converts the locale to Gettext format' do
      expect(described_class.to_gettext(locale: 'en_GB')).to eql('en_GB')
      expect(described_class.to_gettext(locale: 'en-GB')).to eql('en_GB')
      expect(described_class.to_gettext(locale: 'en|GB')).to eql('en_GB')
    end
  end

  describe '#with_preferred_locale(recipient, &)' do
    let(:recipient) { create(:user, language: @default) }
    it "uses the recipient's preferred locale when it is different from I18n.locale. " \
       'I18n.locale is restored after completion.' do
      current_locale = I18n.locale

      expect(I18n.locale).to_not eq(recipient.language.abbreviation)
      described_class.with_preferred_locale(recipient) do
        # I18n.locale == recipient.language.abbreviation within the `with_preferred_locale` block
        expect(I18n.locale.to_s).to eq(recipient.language.abbreviation)
      end
      # I18n.locale is restored after the `with_preferred_locale` block
      expect(I18n.locale).to eq(current_locale)
    end

    it "Uses I18n.locale when recipient doesn't respond to `.language.abbreviation`." do
      current_locale = I18n.locale

      described_class.with_preferred_locale(nil) do
        # I18n.locale doesn't change when recipient.language.abbreviation is falsy
        expect(I18n.locale).to eq(current_locale)
      end
    end
  end

  describe '#with_each_available_locale' do
    it 'yields once for each available locale, and restores I18n.locale after completion.' do
      yielded_locales = []

      LocaleService.with_each_available_locale { |locale| yielded_locales << locale }

      expect(yielded_locales).to eq(I18n.available_locales)
      # Verify .count > 1 to increase our testing confidence
      expect(yielded_locales.count).to be > 1
    end
  end

  describe '#translations_for_all_locales(string)' do
    before do
      # Override `I18n.available_locales` value to match DMP Assistant
      # (LocaleService.translations_for_all_locales calls I18n.available_locales, NOT LocaleService.available_locales)
      # TODO: Consider configuring the test locales to match those used within the actual app.
      I18n.available_locales = %i[en-CA fr-CA]
    end
    it 'returns an array containing all translations of a string, across all available locales' do
      # Use a string that has an existing translation in `config/locale/fr_CA/LC_MESSAGES/app.mo`
      string = 'Create plans'
      expect(described_class.translations_for_all_locales(string)).to eql(['Create plans', 'Créer des plans'])
    end
    it 'Handles edge cases' do
      # When a string with no available translations is provided
      expect(described_class.translations_for_all_locales('RANDOM XYZ123 STRING')).to eql(['RANDOM XYZ123 STRING'])
      # When an empty string is provided
      expect(described_class.translations_for_all_locales('')).to eql([])
      # When a nil value is provided
      expect(described_class.translations_for_all_locales(nil)).to eql([])
    end
  end

  context 'private methods' do
    describe '#convert(string:, join_char:)' do
      it 'handles a 2 character locale (e.g. `en`)' do
        expect(described_class.send(:convert, string: 'en')).to eql('en')
      end
      it 'handles a locale with an extension (e.g. `en-GB`)' do
        expect(described_class.send(:convert, string: 'en|GB')).to eql('en_GB')
      end
      it 'handles a locale as upper case (e.g. `EN-GB`)' do
        expect(described_class.send(:convert, string: 'EN|GB')).to eql('en_GB')
      end
      it 'handles a locale as lower case (e.g. `en-gb`)' do
        expect(described_class.send(:convert, string: 'en|gb')).to eql('en_GB')
      end
      it 'uses the specified join_char' do
        result = described_class.send(:convert, string: 'en|gb', join_char: '+')
        expect(result).to eql('en+GB')
      end
      it 'defaults to Gettext join_char' do
        expect(described_class.send(:convert, string: 'en-GB')).to eql('en_GB')
      end
    end
  end
end
