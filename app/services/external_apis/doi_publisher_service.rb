# frozen_string_literal: true

module ExternalApis
  # This service handles DOI minting for DMPs by connecting to DataCiteService
  class DoiPublisherService
    class << self
      def publish_snapshot(snapshot) # rubocop:disable Metrics/AbcSize,Metrics/MethodLength
        plan = snapshot.plan
        datacite_scheme = IdentifierScheme.find_by(name: 'datacite')
        raise 'DataCite IdentifierScheme missing' if datacite_scheme.blank?

        # Return existing DOI if snapshot was already published
        existing_snapshot_doi = Identifier.find_by(
          identifiable: snapshot,
          identifier_scheme: datacite_scheme
        )
        return existing_snapshot_doi.value if existing_snapshot_doi.present?

        # 1. Fetch or mint Canonical DOI
        canonical_identifier = plan.identifiers.find_by(identifier_scheme: datacite_scheme)
        canonical_identifier = mint_canonical_doi(plan, snapshot, datacite_scheme) if canonical_identifier.blank?

        # 2. Find prior snapshot DOI
        previous_identifier = Identifier.where(
          identifiable: plan.snapshots.where('created_at < ?', snapshot.created_at),
          identifier_scheme: datacite_scheme
        ).order(created_at: :desc).first

        # 3. Mint Snapshot DOI
        mint_snapshot_doi(
          plan: plan,
          snapshot: snapshot,
          datacite_scheme: datacite_scheme,
          canonical_doi: canonical_identifier.value,
          previous_doi: previous_identifier&.value
        )

        # 4. Update Canonical DOI (add HasVersion)
        update_canonical_doi(
          plan: plan,
          snapshot: snapshot,
          datacite_scheme: datacite_scheme,
          canonical_doi_url: canonical_identifier.value
        )
      end
    end
  end
end
