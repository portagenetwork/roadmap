# frozen_string_literal: true

module ExternalApis
  # This service calls DataCite and Crossref services accordingly when parsing DOIs
  class DoiResolutionService
    class << self
      # Matches ~99% of modern Crossref DOIs
      MODERN_DOI_REGEX = %r{10\.\d{4,9}/[-._;()/:A-Z0-9]+}i

      # Catch-all for early DOIs with complex/opaque formatting
      OLD_DOI_REGEX = %r{10\.1002/[^\s]+}i

      # Main function for the "Add Research Output by DOI" feature
      def fetch_metadata(doi:)
        return nil if doi.blank?

        # Strip 'https://doi.org/'
        clean_doi = doi.strip.gsub(%r{^https?://doi.org/}, '')
        # Validate DOIs with regex
        # See https://www.crossref.org/blog/dois-and-matching-regular-expressions/ for more
        return nil unless doi.to_s.match?(MODERN_DOI_REGEX) || doi.to_s.match?(OLD_DOI_REGEX)

        # Try DataCite first
        metadata = execute_fetch(ExternalApis::DataciteService, 'datacite', clean_doi)
        return metadata if metadata.present?

        # Fall back to Crossref
        execute_fetch(ExternalApis::CrossrefService, 'crossref', clean_doi)
      end

      private

      def execute_fetch(service_module, service_name, clean_doi)
        return nil unless service_module.active?

        cache_key = "#{service_name}/metadata/#{clean_doi}"

        # Cache the result for 5 minutes. If this DOI is requested again within 5 minutes
        # Rails returns the cached hash instantly.
        Rails.cache.fetch(cache_key, expires_in: 5.minutes, skip_nil: true) do
          response = service_module.execute_api_get(clean_doi)
          return nil unless response&.code == 200

          service_module.parse_attributes(response.body, clean_doi)
        end
      rescue SocketError, HTTParty::Error, Timeout::Error, JSON::ParserError => e
        service_module.log_and_notify_error(e, clean_doi)
      end
    end
  end
end
