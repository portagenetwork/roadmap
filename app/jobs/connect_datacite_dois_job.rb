class ConnectDataciteDoisJob < ApplicationJob
  queue_as :default

  def perform(plan:, snapshot:)
    # Mint canonical DOI if missing
    canonical_doi = plan.dmp_id || DmpIdService.mint_dmp_id(snapshot: snapshot, is_canonical: true)

    # Link canonical DOI and new snapshot DOI to each other
    ExternalApis::DataciteService.link_canonical_and_version_dois(canonical_doi, snapshot.dmp_id)

    # If a previous public snapshot exists, link its DOI with the new snapshot DOI
    previous_snapshot = plan.previous_public_snapshot(snapshot)
    if previous_snapshot&.dmp_id
      ExternalApis::DataciteService.link_previous_and_new_version_dois(previous_snapshot.dmp_id,
                                                                       snapshot.dmp_id)
    end
  rescue StandardError => e
    Rails.logger.error("ConnectDataciteDoisJob failed for snapshot #{snapshot.dmp_id}: #{e.message}")
    Sentry.capture_exception(e) if defined?(Sentry)
  end
end
