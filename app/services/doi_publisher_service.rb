# frozen_string_literal: true

# This service handles DOI minting for DMPs by connecting to DataCiteService
class DoiPublisherService
  class << self
    def publish_snapshot(snapshot) # rubocop:disable Metrics/AbcSize,Metrics/MethodLength
      plan = snapshot.plan
      datacite_scheme = IdentifierScheme.find_by(name: 'datacite')
      raise 'DataCite IdentifierScheme missing' if datacite_scheme.blank?

      # Return existing DOI if snapshot was already published
      return snapshot.doi if snapshot.doi.present?

      # 1. Fetch or mint Canonical DOI
      canonical_identifier = plan.dmp_id || mint_canonical_doi(plan, snapshot, datacite_scheme)

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
      payload = datacite_payload(plan: plan, snapshot: snapshot, is_canonical: true)

      response = ExternalApis::DataciteService.mint_doi(payload: payload)
      doi_url = "#{datacite_scheme.identifier_prefix}#{response.dig('data', 'id')}"

      plan.identifiers.create!(identifier_scheme: datacite_scheme, value: doi_url)
    end

    def mint_snapshot_doi(plan:, snapshot:, datacite_scheme:, canonical_doi:, previous_doi:)
      payload = datacite_payload(
        plan: plan,
        snapshot: snapshot,
        is_canonical: false,
        canonical_doi: canonical_doi,
        previous_doi: previous_doi
      )

      response = ExternalApis::DataciteService.mint_doi(payload: payload)
      doi_url = "#{datacite_scheme.identifier_prefix}#{response.dig('data', 'id')}"

      Identifier.create!(
        identifiable: snapshot,
        identifier_scheme: datacite_scheme,
        value: doi_url
      )
    end

    def update_canonical_doi(plan:, snapshot:, datacite_scheme:, canonical_doi_url:)
      clean_canonical_id = canonical_doi_url.delete_prefix(datacite_scheme.identifier_prefix)

      # Collect all snapshot DOIs for this plan
      has_version_dois = Identifier.for_plan_snapshot
                                   .where(identifiable_id: plan.snapshots)

      payload = datacite_payload(
        plan: plan,
        snapshot: snapshot,
        is_canonical: true,
        has_version_dois: has_version_dois
      )
      payload['data']['id'] = clean_canonical_id

      ExternalApis::DataciteService.update_doi(
        doi_id: clean_canonical_id,
        payload: payload
      )
    end

    def datacite_payload(plan:, snapshot:, is_canonical:, **extra_locals)
      json_output = ApplicationController.renderer.render(
        template: 'datacite/_plan',
        formats: [:json],
        locals: {
          plan: plan,
          snapshot: snapshot,
          is_canonical: is_canonical,
          **extra_locals
        }
      )

      payload = JSON.parse(json_output)
      payload['data']['attributes']['event'] = 'draft'
      payload
    end
  end
end
