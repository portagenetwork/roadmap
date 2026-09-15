# app/jobs/publish_doi_job.rb
# frozen_string_literal: true

# Background job that performs DOI Publication for Plan Snapshots
class PublishDoiJob < ApplicationJob
  queue_as :default

  retry_on HTTParty::Error, StandardError, wait: :exponentially_longer, attempts: 3

  def perform(snapshot)
    return unless snapshot&.persisted? && snapshot.plan&.publicly_visible?

    DoiPublisherService.publish_snapshot(snapshot)
  rescue StandardError => e
    Rails.logger.error("PublishDoiJob failed for PlanSnapshot ##{snapshot&.id}: #{e.message}")
    Rollbar.error(e, "PublishDoiJob failed for PlanSnapshot ##{snapshot&.id}") if defined?(Rollbar)
    raise e
  end
end
