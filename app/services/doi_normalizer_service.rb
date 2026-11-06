# frozen_string_literal: true

# Service for standardizing DOI formatting
class DoiNormalizerService
  DEFAULT_PREFIX = 'https://doi.org/'

  class << self
    # Extracts raw DOI string (e.g. "10.83996/xyz") by stripping HTTP domains
    def bare_doi(doi_string)
      return nil if doi_string.blank?

      doi_string.to_s.sub(%r{\Ahttps?://[^/]+/}, '')
    end

    # Formats a raw DOI into a resolvable URL string using scheme prefix or default
    def full_url(doi_id, scheme_prefix: nil)
      return nil if doi_id.blank?

      clean_id = bare_doi(doi_id)
      prefix = scheme_prefix.presence || DEFAULT_PREFIX
      prefix = "#{prefix}/" unless prefix.end_with?('/')

      "#{prefix}#{clean_id}"
    end
  end
end
