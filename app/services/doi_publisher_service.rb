# frozen_string_literal: true

# This service handles DOI minting for DMPs by connecting to DataCiteService
class DoiPublisherService
  class << self
    # 1. SYNCHRONOUS (Controller): Mints snapshot DOI inside database transaction
    def publish_snapshot_doi(snapshot)
      plan = snapshot.plan

      return snapshot.doi if snapshot.doi.present?

      mint_snapshot_doi(
        plan: plan,
        snapshot: snapshot,
        canonical_doi: plan.dmp_id&.value,
        previous_doi: snapshot.previous_doi&.value
      )
    end

    # 2. ASYNCHRONOUS (PublishDoiJob): Mints canonical DOI & syncs bidirectional DataCite relationships
    def publish_canonical_and_relationships(snapshot)
      plan = snapshot.plan

      # Fetch or mint Canonical DMP DOI
      canonical_identifier = plan.dmp_id || mint_canonical_doi(plan, snapshot)

      # Update Canonical DMP metadata at DataCite (HasVersion -> snapshot DOIs)
      update_canonical_doi(
        plan: plan,
        snapshot: snapshot,
        canonical_doi_url: canonical_identifier.value
      )

      # Update Snapshot metadata at DataCite (IsVersionOf -> canonical DOI)
      update_snapshot_doi(
        plan: plan,
        snapshot: snapshot,
        canonical_doi_url: canonical_identifier.value
      )
    end

    private

    def mint_canonical_doi(plan, snapshot)
      datacite_scheme = IdentifierScheme.datacite
      payload = datacite_payload(plan: plan, snapshot: snapshot, is_canonical: true)

      response = ExternalApis::DataciteService.mint_doi(payload: payload)
      doi_url = DoiNormalizerService.full_url(
        response.dig('data', 'id'),
        scheme_prefix: datacite_scheme.identifier_prefix
      )

      plan.identifiers.create!(identifier_scheme: datacite_scheme, value: doi_url)
    end

    def mint_snapshot_doi(plan:, snapshot:, canonical_doi:, previous_doi:)
      datacite_scheme = IdentifierScheme.datacite
      payload = datacite_payload(
        plan: plan,
        snapshot: snapshot,
        is_canonical: false,
        canonical_doi: canonical_doi,
        previous_doi: previous_doi
      )

      response = ExternalApis::DataciteService.mint_doi(payload: payload)
      doi_url = DoiNormalizerService.full_url(
        response.dig('data', 'id'),
        scheme_prefix: datacite_scheme.identifier_prefix
      )

      snapshot.create_identifier!(
        identifier_scheme: datacite_scheme,
        value: doi_url
      )
    end

    def update_canonical_doi(plan:, snapshot:, canonical_doi_url:)
      clean_canonical_id = DoiNormalizerService.bare_doi(canonical_doi_url)

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

    def update_snapshot_doi(plan:, snapshot:, canonical_doi_url:)
      snapshot_identifier = snapshot.identifier
      return if snapshot_identifier.blank?

      clean_snapshot_id = DoiNormalizerService.bare_doi(snapshot_identifier.value)

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
