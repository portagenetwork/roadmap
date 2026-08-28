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

      private

      def mint_canonical_doi(plan, snapshot, datacite_scheme)
        json_output = ApplicationController.renderer.render(
          template: 'datacite/_plan_snapshot',
          formats: [:json],
          locals: { plan: plan, snapshot: snapshot, is_canonical: true }
        )

        payload = JSON.parse(json_output)
        # Temporary for testing
        payload['data']['attributes']['event'] = 'draft'

        response = ExternalApis::DataciteService.mint_doi(payload: payload)
        doi_url = "https://doi.org/#{response.dig('data', 'id')}"

        plan.identifiers.create!(identifier_scheme: datacite_scheme, value: doi_url)
      end

      def mint_snapshot_doi(plan:, snapshot:, datacite_scheme:, canonical_doi:, previous_doi:)
        json_output = ApplicationController.renderer.render(
          template: 'datacite/_plan_snapshot',
          formats: [:json],
          locals: {
            plan: plan,
            snapshot: snapshot,
            is_canonical: false,
            canonical_doi: canonical_doi,
            previous_doi: previous_doi
          }
        )

        payload = JSON.parse(json_output)
        payload['data']['attributes']['event'] = 'draft'

        response = ExternalApis::DataciteService.mint_doi(payload: payload)
        doi_url = "https://doi.org/#{response.dig('data', 'id')}"

        Identifier.create!(
          identifiable: snapshot,
          identifier_scheme: datacite_scheme,
          value: doi_url
        )
      end

      def update_canonical_doi(plan:, snapshot:, datacite_scheme:, canonical_doi_url:) # rubocop:disable Metrics/MethodLength
        clean_canonical_id = canonical_doi_url.gsub(%r{^https?://doi\.org/}, '')

        # Collect all snapshot DOIs for this plan
        snapshot_ids = plan.snapshots.pluck(:id)
        has_version_dois = Identifier.where(
          identifiable_type: 'PlanSnapshot',
          identifiable_id: snapshot_ids,
          identifier_scheme_id: datacite_scheme.id
        ).pluck(:value)

        json_output = ApplicationController.renderer.render(
          template: 'datacite/_plan_snapshot',
          formats: [:json],
          locals: {
            plan: plan,
            snapshot: snapshot,
            is_canonical: true,
            has_version_dois: has_version_dois
          }
        )

        payload = JSON.parse(json_output)
        payload['data']['id'] = clean_canonical_id
        payload['data']['attributes']['event'] = 'draft'

        ExternalApis::DataciteService.update_doi(
          doi_id: clean_canonical_id,
          payload: payload
        )
      end
    end
  end
end
