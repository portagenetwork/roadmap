# frozen_string_literal: true

module ExternalApis
  # This service provides an interface to the Research Organization Registry (ROR)
  # API.
  # For more information: https://github.com/ror-community/ror-api
  class RorService < BaseService
    class << self
      # Retrieve the config settings from the initializer
      def landing_page_url
        Rails.configuration.x.ror&.landing_page_url || super
      end

      def api_base_url
        Rails.configuration.x.ror&.api_base_url || super
      end

      def max_pages
        Rails.configuration.x.ror&.max_pages || super
      end

      def max_results_per_page
        Rails.configuration.x.ror&.max_results_per_page || super
      end

      def max_redirects
        Rails.configuration.x.ror&.max_redirects || super
      end

      def active?
        Rails.configuration.x.ror&.active || super
      end

      def heartbeat_path
        Rails.configuration.x.ror&.heartbeat_path
      end

      def search_path
        Rails.configuration.x.ror&.search_path
      end

      # Ping the ROR API to determine if it is online
      #
      # @return true/false
      def ping
        return true unless active? && heartbeat_path.present?

        resp = http_get(uri: "#{api_base_url}#{heartbeat_path}")
        resp.present? && resp.code == 200
      end

      # Search the ROR API for the given string.
      #
      # @return an Array of Hashes:
      # {
      #   id: 'https://ror.org/12345',
      #   name: 'Sample University (sample.edu)',
      #   sort_name: 'Sample University',
      #   score: 0
      #   weight: 0
      # }
      # The ROR limit appears to be 40 results (even with paging :/)
      def search(term:, filters: [])
        return [] unless active? && term.present? && ping

        process_pages(
          term: term,
          json: query_ror(term: term, filters: filters),
          filters: filters
        )

      # If a JSON parse error occurs then return results of a local table search
      rescue JSON::ParserError => e
        log_error(method: 'ROR search', error: e)
        []
      end

      private

      # Queries the ROR API for the specified name and page
      def query_ror(term:, page: 1, filters: [])
        return [] unless term.present?

        # Percent-encode the term
        # (HTTParty.get() throws InvalidURIError when given non-ASCII characters)
        encoded_term = URI.encode_www_form_component(term)

        # build the URL
        target = "#{api_base_url}#{search_path}"
        query = query_string(term: encoded_term, page: page, filters: filters)

        # Call the ROR API and log any errors
        resp = http_get(uri: "#{target}?#{query}", additional_headers: {},
                        debug: false)

        unless resp.present? && resp.code == 200
          handle_http_failure(method: 'ROR search', http_response: resp)
          return []
        end
        JSON.parse(resp.body)
      end

      # Build the query string using the search term, current page and any
      # filters specified
      def query_string(term:, page: 1, filters: [])
        query_string = ["query=#{term}", "page=#{page}"]
        query_string << "filter=#{filters.join(',')}" if filters.any?
        query_string.join('&')
      end

      # Recursive method that can handle multiple ROR result pages if necessary
      # rubocop:disable Metrics/AbcSize
      def process_pages(term:, json:, filters: [])
        return [] if json.blank?

        results = parse_results(json: json)
        num_of_results = json.fetch('number_of_results', 1).to_i

        # Determine if there are multiple pages of results
        pages = (num_of_results / max_results_per_page.to_f).to_f.ceil
        return results unless pages > 1

        # Gather the results from the additional page (only up to the max)
        (2..([pages, max_pages].min)).each do |page|
          json = query_ror(term: term, page: page, filters: filters)
          results += parse_results(json: json)
        end
        results || []

      # If we encounter a JSON parse error on subsequent page requests then just
      # return what we have so far
      rescue JSON::ParserError => e
        log_error(method: 'ROR search', error: e)
        results || []
      end
      # rubocop:enable Metrics/AbcSize

      # Convert the JSON items into a hash
      # rubocop:disable Metrics/AbcSize
      def parse_results(json:)
        results = []
        return results unless json.present? && json.fetch('items', []).any?

        json['items'].each do |item|
          results << {
            ror: item['id'].gsub(/^#{landing_page_url}/, ''),
            name: org_name(item: item),
            sort_name: sort_name(item: item),
            url: org_url(item: item),
            language: org_language(item: item),
            fundref: fundref_id(item: item),
            abbreviation: item.fetch('acronyms', []).first
          }
        rescue KeyError, NoMethodError => e
          Rails.logger.error(
            "Invalid ROR record: #{e.class} - #{e.message}, item: #{item.inspect}"
          )
        end
        results
      end
      # rubocop:enable Metrics/AbcSize

      def ror_display_entry(item:)
        item['names'].find { |n| n['types'].include?('ror_display') }
      end

      # Extracts the org's display name from `names` to be used as sort_name
      # "names": [
      #     {"lang": "en", "types": ["ror_display","label"], "value": "Harvard University"},
      #     {"lang": "es","types": ["label"], "value": "Universidad de Harvard"}
      # ]
      def sort_name(item:)
        ror_display_entry(item: item).fetch('value')
      end

      # Returns the website link value
      # "links": [
      #   { "type": "website", "value": "https://example.edu" },
      #   { "type": "Wikipedia", "value": "https://en.wikipedia.org/wiki/Example_University" }
      # ]
      def org_url(item:)
        links = item['links']
        # links must not be empty
        return nil unless links.present?

        links.find { |l| l['type'] == 'website' }&.fetch('value')
      end

      # Org names are not unique, so include the Org URL if available or
      # the country. For example:
      #    "Example College (example.edu)"
      #    "Example College (Brazil)"
      def org_name(item:)
        name = sort_name(item: item)

        country = item.fetch('country', {}).fetch('country_name', '')
        website = org_website(item: item)

        # If no website or country then just return the name
        return name unless website.present? || country.present?

        # Otherwise return the contextualized name
        "#{name} (#{website || country})"
      end

      # Extracts the org's language
      # {
      #   "id": "https://ror.org/012345678",
      #   "names": [
      #     { "value": "Université de Montréal", "types": ["ror_display"], "lang": "fr" },
      #     { "value": "University of Montreal", "types": ["alias"], "lang": "en" }
      #   ]
      # }
      def org_language(item:)
        # ROR uses two-letter / ISO 639-1 language codes (e.g. "en")
        dflt = I18n.default_locale.to_s.split('-').first

        ror_display_entry(item: item)['lang'] || dflt
      end

      # Extracts the website domain from the item
      # "links": [
      #   { "type": "website", "value": "https://example.edu" },
      #   { "type": "Wikipedia", "value": "https://en.wikipedia.org/wiki/Example_University" }
      # ]
      def org_website(item:)
        link = org_url(item: item)
        return nil unless link.present?

        # A website was found, so extract just the domain without the www
        domain_regex = %r{^(?:http://|www\.|https://)([^/]+)}
        website = link.scan(domain_regex).last.first
        website.gsub('www.', '')
      end

      # Extracts the FundRef Id from external ids if available
      # "external_ids": [
      #   {"type": "fundref", "preferred": "12345", "all": ["12345", "67890"]},
      #   {"type": "SomeOtherID", "preferred": "501100000000", "all": ["501100000000"]}
      # ]
      def fundref_id(item:)
        external_ids = item['external_ids']

        fundref = external_ids.find { |id| id['type'] == 'fundref' }
        return '' unless fundref.present?

        # If a preferred Id was specified then use it
        preferred = fundref['preferred']
        return preferred if preferred.present?

        # Otherwise take the first one listed
        all = fundref['all']
        return all.first if all.present?

        ''
      end
    end
  end
end
