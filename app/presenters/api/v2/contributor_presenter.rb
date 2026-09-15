# frozen_string_literal: true

module Api
  module V2
    # Helper class for the API V2 contributors views
    class ContributorPresenter
      class << self
        # Convert the specified role into a CRediT Taxonomy URL
        def role_as_uri(role:)
          return nil unless role.present?
          return 'other' if role.to_s.casecmp('other').zero?

          "#{Contributor::ONTOLOGY_BASE_URL}#{role.to_s.downcase.tr('_', '-')}"
        end

        # NOTE: This currently assumes ORCID is the canonical identifier for a
        # contributor/contact, but the Common-MaDMP schema allows other identifier
        # types and the app may not have ORCID for every person. For records with
        # no ORCID, we may need a fallback strategy such as email/mbox, but this
        # should be treated as an app compatibility fallback rather than a schema-
        # compliant identifier type.
        def contributor_id(identifiers:)
          identifiers.find { |id| id.identifier_scheme.name == 'orcid' }
        end
      end
    end
  end
end
