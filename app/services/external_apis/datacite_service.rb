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
      def fetch_metadata(doi:) # rubocop:disable Metrics/AbcSize
        return nil unless active? && doi.present?

        # Strip 'https://doi.org/'
        clean_doi = doi.strip.gsub(%r{^https?://doi.org/}, '')

        url = "#{api_base_url}/dois/#{CGI.escape(clean_doi)}"

        response = HTTParty.get(url, headers: { 'Accept' => 'application/vnd.api+json' })
        return nil unless response.code == 200

        json = JSON.parse(response.body).with_indifferent_access
        attributes = json.dig(:data, :attributes)
        return nil if attributes.blank?

        {
          # Find the title of the first item in the titles array
          title: attributes.dig(:titles, 0, :title),
          description: extract_description(attributes),
          output_type: ResearchOutput.output_type_from_datacite(attributes.dig(:types, :resourceTypeGeneral)),
          release_date: attributes[:published],
          doi: clean_doi
        }
      rescue SocketError, HTTParty::Error, Timeout::Error, JSON::ParserError => e
        Rails.logger.error "DataCite Service Error [fetch_metadata]: #{e.message}"
        nil
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
    end
  end
end
