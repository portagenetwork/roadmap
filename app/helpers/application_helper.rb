# frozen_string_literal: true

# Generic helper methods
module ApplicationHelper
  def resource_name
    :user
  end

  # ---------------------------------------------------------------------------
  def resource
    @resource ||= User.new
  end

  # ---------------------------------------------------------------------------
  def devise_mapping
    @devise_mapping ||= Devise.mappings[:user]
  end

  # Determines whether or not the URL path passed matches with the full path (including
  # params) of the last URL requested. See
  # http://api.rubyonrails.org/classes/ActionDispatch/Request.html#method-i-fullpath
  # for details
  # rubocop:disable Style/OptionalBooleanParameter
  def active_page?(path, exact_match = false)
    if exact_match
      request.fullpath == path
    else
      request.fullpath.include?(path)
    end
  end
  # rubocop:enable Style/OptionalBooleanParameter

  alias isActivePage active_page?

  deprecate :isActivePage, deprecator: Cleanup::Deprecators::PredicateDeprecator.new

  def fingerprinted_asset(name)
    Rails.env.production? ? "#{name}-#{ASSET_FINGERPRINT}" : name
  end

  def title(page_title)
    content_for(:title) { page_title }
  end

  # This method assumes there will be an image file called dmp_logo_xx-XX.png
  # where xx-XX is the string formatted I18n.locale.
  # e.g. if I18n.locale == :'en_CA', then "#{I18n.locale}" == 'en-CA'
  def current_locale_logo
    if FeatureFlagHelper.enabled?(:on_sandbox)
      "sandbox_logo_#{I18n.locale}.png"
    else
      "dmp_logo_#{I18n.locale}.png"
    end
  end

  def contact_us_path
    if I18n.locale == :'fr-CA'
      'https://portagenetwork.ca/fr/contactez-nous/'
    else
      # Handling :'en-CA' locale
      'https://portagenetwork.ca/contact-us/'
    end
  end

  # Regardless of locale, we are currently only routing to '/terms'
  # This will be changed when the French terms route is made available
  def terms_of_use_path
    'https://assistant.portagenetwork.ca/terms'
    # if I18n.locale == :'fr-CA'
    #   'https://portagenetwork.ca/fr/outils-et-ressources/assistant-pgd/conditions-dutilisation-de-lassistant-pgd/'
    # else
    #   # Handling :'en-CA' locale
    #   'https://assistant.portagenetwork.ca/terms'
    # end
  end

  def how_to_manage_your_data_path
    if I18n.locale == :'fr-CA'
      'https://portagenetwork.ca/fr/outils-et-ressources/assistant-pgd/comment-gerer-vos-donnees/'
    else
      # Handling :'en-CA' locale
      'https://portagenetwork.ca/tools-and-resources/dmp-assistant/how-to-manage-your-data/'
    end
  end

  def contacts_at_your_instutution_path
    if I18n.locale == :'fr-CA'
      'https://alliancecan.ca/fr/services/gestion-des-donnees-de-recherche/apprentissage-et-ressources/personnes-ressources-dans-les-etablissements'
    else
      # Handling :'en-CA' locale
      'https://alliancecan.ca/en/services/research-data-management/learning-and-training/institutional-contacts'
    end
  end

  def unique_dom_id(record, prefix = nil)
    klass     = dom_class(record, prefix)
    record_id = record_key_for_dom_id(record) || record.object_id
    "#{klass}_#{record_id}"
  end
end
