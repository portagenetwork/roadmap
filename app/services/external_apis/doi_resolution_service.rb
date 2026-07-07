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
        return { status: :blank } if doi.blank?

        # Strip 'https://doi.org/'
        clean_doi = doi.strip.gsub(%r{^https?://doi.org/}, '')

        # Validate DOIs with regex
        # See https://www.crossref.org/blog/dois-and-matching-regular-expressions/ for more
        return { status: :invalid } unless clean_doi.match?(MODERN_DOI_REGEX) || clean_doi.match?(OLD_DOI_REGEX)

        metadata = execute_fetch(ExternalApis::DataciteService, 'datacite', clean_doi)
        # Fall back to Crossref if DataCite does not return anything
        metadata ||= execute_fetch(ExternalApis::CrossrefService, 'crossref', clean_doi)

        if metadata.present?
          { status: :ok, metadata: metadata }
        else
          { status: :not_found }
        end
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
