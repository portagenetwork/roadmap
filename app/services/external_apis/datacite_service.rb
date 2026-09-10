# frozen_string_literal: true

require 'cgi'
module ExternalApis
  # This service provides an interface to the DataCite API
  class DataciteService < BaseService
    class << self
      def api_base_url
        Rails.configuration.x.datacite&.api_base_url || super
      end

      def test_api_base_url
        Rails.configuration.x.datacite&.test_api_base_url || super
      end

      def current_api_base_url
        Rails.env.production? ? api_base_url : test_api_base_url
      end

      def auth_repository_id
        Rails.configuration.x.datacite&.repository_id
      end

      def auth_password
        Rails.configuration.x.datacite&.password
      end

      def active?
        Rails.configuration.x.datacite&.active || false
      end

      # Mints a new DOI via DataCite REST API (POST /dois)
      def mint_doi(payload:)
        perform_request(:post, '/dois', payload)
      end

      # Updates an existing DOI record via DataCite REST API (PUT /dois/:id)
      # Used to update canonical DOIs to include all snapshot DOIs
      def update_doi(doi_id:, payload:)
        clean_id = doi_id.gsub(%r{^https?://doi\.org/}, '')
        endpoint = "/dois/#{CGI.escape(clean_id)}"
        perform_request(:put, endpoint, payload)
      end

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
        HTTParty.get(
          url,
          headers: { 'Accept' => 'application/vnd.api+json' },
          open_timeout: 5,
          read_timeout: 5
        )
      end

      def parse_attributes(body, clean_doi)
        json = JSON.parse(body).with_indifferent_access
        attributes = json.dig(:data, :attributes)
        return nil if attributes.blank?

        {
          title: attributes.dig(:titles, 0, :title),
          description: extract_description(attributes),
          output_type: ResearchOutput.output_type_from_datacite(attributes.dig(:types, :resourceTypeGeneral)),
          # There are various types of release dates available, but few return full dates (YYYY-MM-DD)
          # registered release dates provide the exact date the DOI became findable
          release_date: attributes[:registered],
          doi: clean_doi
        }
      end

      def log_and_notify_error(error, doi)
        # Local logs for immediate debugging
        Rails.logger.error "DataCite Service Error: #{error.message}"
        # External error tracking to notify the team
        Rollbar.error(error, "DataCite Service Error for DOI: #{doi}")
        nil
      end

      private

      def perform_request(http_method, endpoint, payload)
        raise 'DataCite integration is disabled or credentials missing.' unless active?

        url = "#{current_api_base_url}#{endpoint}"
        response = HTTParty.public_send(http_method, url, request_body(payload))

        raise "DataCite API Error [#{response.code}]: #{response.body}" unless response.success?

        JSON.parse(response.body)
      rescue StandardError => e
        log_and_notify_error(e, "#{http_method.to_s.upcase} #{endpoint}")
        raise
      end

      def request_body(payload)
        {
          body: payload.is_a?(String) ? payload : payload.to_json,
          headers: {
            'Content-Type' => 'application/vnd.api+json',
            'Accept' => 'application/vnd.api+json'
          },
          basic_auth: {
            username: auth_repository_id,
            password: auth_password
          },
          open_timeout: 10,
          read_timeout: 10
        }
      end
    end
  end
end
