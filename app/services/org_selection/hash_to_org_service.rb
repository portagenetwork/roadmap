# frozen_string_literal: true

require 'text'

module OrgSelection
  # This class provides conversion methods for turning OrgSelection::Search
  # results into Orgs and Identifiers
  # For example:
  # {
  #   ror: "http://ror.org/123",
  #   name: "Foo (foo.org)",
  #   sort_name: "Foo"
  # }
  # becomes:
  # An Org with name = "Foo (foo.org)",
  #             identifier (ROR) = "http://example.org/123"
  #
  class HashToOrgService
    class << self
      def to_org(hash:, allow_create: true)
        return nil unless hash.present?

        # Allow for the hash to have either symbol or string keys
        hash = hash.with_indifferent_access

        # 1st: if id is present - find the Org and then verify names match
        org = lookup_org_by_id(hash: hash)
        return org if org.present?

        # 2nd: Search by the external identifiers (e.g. "ror", "fundref", etc.)
        # and then verify a name match
        org = lookup_org_by_identifiers(hash: hash)
        return org if org.present?

        # 3rd: Search by name and then verify exact_match
        org = lookup_org_by_name(hash: hash)
        return org if org.present?

        # Otherwise: Create an Org if allowed
        allow_create ? initialize_org(hash: hash) : nil
      end

      # rubocop:disable Metrics/AbcSize
      def to_identifiers(hash:)
        return [] unless hash.present?

        out = []
        # Process each of the identifiers
        hash = hash.with_indifferent_access
        idents = hash.select { |k, _v| identifier_keys.include?(k) }
        idents.each do |key, value|
          attrs = hash.select { |k, _v| attr_keys(hash: hash).include?(k) }
          attrs = {} unless attrs.present?
          out << Identifier.new(
            identifier_scheme_id: IdentifierScheme.by_name(key).first&.id,
            value: value,
            attrs: attrs
          )
        end
        out
      end
      # rubocop:enable Metrics/AbcSize

      private

      def match_hash_to_ror_org(hash:)
        return nil unless hash[:ror].present?

        ror_results = OrgSelection::SearchService.search_externally(search_term: hash[:name])
        ror_results&.find { |r| r[:ror] == hash[:ror] }
      end

      # Lookup the Org by it's :id and return if the name matches the search
      def lookup_org_by_id(hash:)
        org = Org.where(id: hash[:id]).first if hash[:id].present?
        exact_match?(rec: org, name2: hash[:name]) ? org : nil
      end

      # Lookup the Org by its :identifiers and return if the name matches the search
      def lookup_org_by_identifiers(hash:)
        identifiers = hash.select { |k, _v| identifier_keys.include?(k) }
        ids = identifiers.map { |k, v| { name: k, value: v } }
        org = Org.from_identifiers(array: ids) if ids.any?
        exact_match?(rec: org, name2: hash[:name]) ? org : nil
      end

      # Lookup the Org by its :name
      def lookup_org_by_name(hash:)
        clean_name = OrgSelection::SearchService.name_without_alias(name: hash[:name])
        # org = Org.search(clean_name).first
        # Part of ISSUE149: if 'any_org_with_test_as_substring' exist already
        # then switch to exact match to solve the bug that 'test' cannot be saved
        # if duplicate org name, return the first (i.e. this org exists)
        org = Org.where(name: clean_name).first
        exact_match?(rec: org, name2: hash[:name]) ? org : nil
      end

      # Initialize a new Org from the hash
      def initialize_org(hash:)
        return nil unless hash.present? && hash[:name].present?

        # Attempt to find an ROR match to the hash
        ror_hash = match_hash_to_ror_org(hash: hash)
        return nil unless ror_hash

        Org.new(
          name: ror_hash[:name],
          links: links_from_hash(name: ror_hash[:name], website: ror_hash[:url]),
          language: language_from_hash(hash: ror_hash),
          target_url: ror_hash[:url],
          institution: true,
          is_other: false,
          abbreviation: abbreviation_from_hash(hash: ror_hash)
        )
      end

      # Convert the name and website into Org.links
      def links_from_hash(name:, website:)
        return { org: [] } unless name.present? && website.present?

        { org: [{ link: website, text: name }] }
      end

      # Converts the Org name over to a unique abbreviation
      def abbreviation_from_hash(hash:)
        return nil unless hash.present?

        return hash[:abbreviation] if hash[:abbreviation].present?

        # Get the first letter of each word if no abbreviiation was provided
        OrgSelection::SearchService.name_without_alias(name: hash[:name])
                                   .split.map(&:first).join.upcase
      end

      # Get the language from the hash or use the default
      def language_from_hash(hash:)
        abbr = hash&.dig(:language)
        # RorService.org_language returns I18n.default_locale.to_s as a fallback
        return Language.default if abbr.blank? || abbr == I18n.default_locale.to_s

        # ROR provides ISO 639-1 codes (e.g., "en"). Attempt to match against BCP 47 tags (e.g., "en-CA") in db
        pattern = "#{ActiveRecord::Base.sanitize_sql_like(abbr)}-%"

        results = Language.where('abbreviation = ?  OR abbreviation LIKE ?', abbr, pattern)
                          .order(default_language: :desc) # prefer default language if multiple results exist
                          .to_a

        # Return (in order): exact match || first pattern match || app default language
        results.find { |lang| lang.abbreviation == abbr } || results.first || Language.default
      end

      def identifier_keys
        IdentifierScheme.for_orgs.pluck(:name)
      end

      def attr_keys(hash:)
        return {} unless hash.present?

        non_attr_keys = identifier_keys + %w[sort_name weight score]
        hash.keys.reject { |k| non_attr_keys.include?(k) }
      end

      def exact_match?(rec:, name2:)
        return false unless rec.present? && name2.present?

        OrgSelection::SearchService.exact_match?(name1: rec.name, name2: name2)
      end
    end
  end
end
