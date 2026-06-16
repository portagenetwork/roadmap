# frozen_string_literal: true

module PlanSnapshots
  # Performs a fixity check for a PlanSnapshot.
  #
  # A checksum comparison is only performed if the snapshot is due for a fixity check
  # (see PlanSnapshot#fixity_check_due?). This avoids re-validating snapshot
  # integrity on every access.
  #
  # Returns a hash with a `status` key indicating the fixity check outcome:
  # - :ok      - the checksum was recalculated and matched the stored checksum;
  #              fixity_checked_at was updated.
  # - :failed  - the checksum was recalculated and did not match the stored
  #              checksum; a Rollbar alert was generated.
  # - :skipped - the snapshot is not yet due for a fixity check and no
  #              validation was performed.
  #
  # Caller example:
  #   result = PlanSnapshots::FixityCheckService.new(snapshot).call
  #   result[:status] #=> :ok, :failed, or :skipped
  class FixityCheckService
    def initialize(snapshot)
      @snapshot = snapshot
    end

    def call
      if !snapshot.fixity_check_due?
        skipped_result
      elsif snapshot.fixity_check_passed?
        success_result
      else
        failure_result
      end
    end

    private

    attr_reader :snapshot

    def skipped_result
      { status: :skipped }
    end

    def success_result
      snapshot.update!(fixity_checked_at: Time.current)
      { status: :ok }
    end

    def failure_result
      log_failure
      { status: :failed }
    end

    def log_failure
      payload = alert_payload

      Rails.logger.error(
        payload.merge(
          message: 'Fixity check failed'
        )
      )

      Rollbar.error('PlanSnapshot fixity check failed', payload)
    end

    def alert_payload
      {
        snapshot_id: snapshot.id,
        plan_id: snapshot.plan_id,
        version: snapshot.version
      }
    end
  end
end
