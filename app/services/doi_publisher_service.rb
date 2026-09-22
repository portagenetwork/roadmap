# frozen_string_literal: true

# This service handles DOI minting for DMPs by connecting to DataCiteService
class DoiPublisherService
  class << self
    # 1. SYNCHRONOUS (Controller): Mints snapshot DOI inside database transaction
    def publish_snapshot_doi(snapshot)
      plan = snapshot.plan
      datacite_scheme = fetch_datacite_scheme

      return snapshot.doi if snapshot.doi.present?

      mint_snapshot_doi(
        plan: plan,
        snapshot: snapshot,
        datacite_scheme: datacite_scheme,
        canonical_doi: plan.dmp_id&.value,
        previous_doi: snapshot.previous_doi&.value
      )
    end

    # 2. ASYNCHRONOUS (PublishDoiJob): Mints canonical DOI & syncs bidirectional DataCite relationships
    def publish_canonical_and_relationships(snapshot)
      plan = snapshot.plan
      datacite_scheme = fetch_datacite_scheme

      # Fetch or mint Canonical DMP DOI
      canonical_identifier = plan.dmp_id || mint_canonical_doi(plan, snapshot, datacite_scheme)

      # Update Canonical DMP metadata at DataCite (HasVersion -> snapshot DOIs)
      update_canonical_doi(
        plan: plan,
        snapshot: snapshot,
        datacite_scheme: datacite_scheme,
        canonical_doi_url: canonical_identifier.value
      )

      # Update Snapshot metadata at DataCite (IsVersionOf -> canonical DOI)
      update_snapshot_doi(
        plan: plan,
        snapshot: snapshot,
        datacite_scheme: datacite_scheme,
        canonical_doi_url: canonical_identifier.value
      )
    end

    private

    def fetch_datacite_scheme
      datacite_scheme = IdentifierScheme.find_by(name: 'datacite')
      raise 'DataCite IdentifierScheme missing' if datacite_scheme.blank?

      datacite_scheme
    end

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

      # Pluck DOI string values so Jbuilder receives array of URL strings
      has_version_dois = Identifier.for_plan_snapshot
                                   .where(identifiable_id: plan.snapshots.pluck(:id))
                                   .pluck(:value)

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

    def update_snapshot_doi(plan:, snapshot:, datacite_scheme:, canonical_doi_url:)
      snapshot_identifier = snapshot.identifier
      return if snapshot_identifier.blank?

      clean_snapshot_id = snapshot_identifier.value.delete_prefix(datacite_scheme.identifier_prefix)

      payload = datacite_payload(
        plan: plan,
        snapshot: snapshot,
        is_canonical: false,
        canonical_doi: canonical_doi_url,
        previous_doi: snapshot.previous_doi&.value
      )
      payload['data']['id'] = clean_snapshot_id

      ExternalApis::DataciteService.update_doi(
        doi_id: clean_snapshot_id,
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
