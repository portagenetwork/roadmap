# frozen_string_literal: true

module Orgs
  # Provides helper methods for inspecting and querying Org associations.
  # Mainly used to find "orphan" orgs and handle special cases,
  # such as funded plans and polymorphic identifiers.
  module AssociationInspector
    # Associations we expect to pass to `where.missing()`
    EXPECTED_ASSOCIATIONS = %i[tracker guidance_groups plans templates users contributors annotations
                               departments].freeze
    HAS_MANY_OR_ONE = %i[has_many has_one].freeze
    EXCLUDED_ASSOCIATIONS = %i[identifiers funded_plans].freeze

    extend self

    # Returns "true" orphan orgs when `allow_funded_plans_association == false`.
    # If `allow_funded_plans_association` is true, funded_plans are ignored,
    # allowing custom queries for orgs that only have funded_plans associations
    # (e.g., used in `CleanupJunkFundersService`).
    def orphan_orgs(allow_funded_plans_association: false)
      base = Org.where.missing(*org_associations)
                # identifiers is a polymorphic association (identifiable_type + identifiable_id),
                # so we cannot use `where.missing(:identifiers)`.
                # Join manually and filter by `identifiable_type = 'Org'`.
                .joins("LEFT JOIN identifiers i ON i.identifiable_type = 'Org' AND i.identifiable_id = orgs.id")
                .where('i.id IS NULL')
      return base if allow_funded_plans_association

      # funded_plans uses a non-standard foreign key (`funder_id`),
      # so we cannot use `where.missing(:funded_plans)`.
      # Alias the join as `funded_plans` to avoid colliding with the regular plans join.
      base.joins('LEFT JOIN plans funded_plans ON funded_plans.funder_id = orgs.id')
          .where('funded_plans.id IS NULL')
    end

    private

    # Associations safe for use with `Org.where.missing()` query
    def org_associations
      associations = Org.reflect_on_all_associations
                        .select { |r| HAS_MANY_OR_ONE.include?(r.macro) }
                        # Exclude associations that cannot be properly handled via `where.missing`:
                        # - identifiers: polymorphic (requires identifiable_type = 'Org' and identifiable_id = orgs.id))
                        # - funded_plans: uses funder_id instead of org_id
                        .reject { |r| EXCLUDED_ASSOCIATIONS.include?(r.name) }
                        .map(&:name)
                        .sort
      verify_expected_associations!(associations)
      associations
    end

    # Raises if the actual associations differ from EXPECTED_ASSOCIATIONS.
    # - Guards against future changes (added or removed associations) that could
    #   affect the `where.missing` query for orphaned orgs.
    def verify_expected_associations!(actual)
      expected = EXPECTED_ASSOCIATIONS.sort
      return if actual == expected

      raise <<~MSG
        Orgs::AssociationInspector detected an association mismatch.
        Expected: #{expected.inspect}
        Actual:   #{actual.inspect}
      MSG
    end
  end
end
