# frozen_string_literal: true

require 'cgi'
module ExternalApis
  # This service provides an interface to the DataCite API
  class DataciteService < BaseService
    class << self
      def api_base_url
        Rails.configuration.x.datacite&.api_base_url || super
      end

      def active?
        Rails.configuration.x.datacite&.active || false
      end

      # Main function for the "Add Research Output by DOI" feature
      def fetch_metadata(doi:)
        return nil unless active? && doi.present?

        # Strip 'https://doi.org/'
        clean_doi = doi.strip.gsub(%r{^https?://doi.org/}, '')

        # Cache the result for 5 minutes. If this DOI is requested again within 5 minutes
        # Rails returns the cached hash instantly.
        Rails.cache.fetch("datacite/metadata/#{clean_doi.parameterize}", expires_in: 5.minutes) do
          response = execute_api_get(clean_doi)
          return nil unless response.code == 200

          parse_datacite_attributes(response.body, clean_doi)
        end
      rescue SocketError, HTTParty::Error, Timeout::Error, JSON::ParserError => e
        log_and_notify_error(e, doi)
      end

      private

      def extract_description(attrs)
        descriptions = attrs[:descriptions]
        return nil if descriptions.blank?

        abstract = descriptions.find { |d| d[:descriptionType] == 'Abstract' }

        # If an abstract hash was found, extract its text content.
        # Otherwise, fall back to the very first text item in the array
        abstract ? abstract[:description] : descriptions.dig(0, :description)
      end

      def execute_api_get(clean_doi)
        url = "#{api_base_url}/dois/#{CGI.escape(clean_doi)}"
        HTTParty.get(url, headers: { 'Accept' => 'application/vnd.api+json' })
      end

      def parse_datacite_attributes(body, clean_doi)
        json = JSON.parse(body).with_indifferent_access
        attributes = json.dig(:data, :attributes)
        return nil if attributes.blank?

        {
          title: attributes.dig(:titles, 0, :title),
          description: extract_description(attributes),
          output_type: ResearchOutput.output_type_from_datacite(attributes.dig(:types, :resourceTypeGeneral)),
          release_date: attributes[:published],
          doi: clean_doi
        }
      end

      def log_and_notify_error(error, doi)
        # Local logs for immediate debugging
        Rails.logger.error "DataCite Service Error [fetch_metadata]: #{error.message}"
        # External error tracking to notify the team
        Rollbar.error(error, "DataCite Service Error [fetch_metadata] for DOI: #{doi}")
        nil
      end
    end
  end
end
