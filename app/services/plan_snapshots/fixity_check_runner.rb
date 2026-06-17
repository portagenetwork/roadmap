# frozen_string_literal: true

module PlanSnapshots
  # Orchestrates fixity checks for all PlanSnapshot records that are currently due.
  # - Fetches snapshots due for fixity validation via `PlanSnapshot.due_for_fixity_check`
  # - Executes `PlanSnapshots::FixityCheckService` for each snapshot
  # - Aggregates results by status (e.g., :ok, :failed, :skipped)
  #
  # Returns:
  # - A Hash with status counts, e.g. { ok: 10, failed: 0 }
  class FixityCheckRunner
    def call
      counts = Hash.new(0)
      snapshots = PlanSnapshot.due_for_fixity_check
      snapshots.find_each do |snapshot|
        result = FixityCheckService.new(snapshot).call
        counts[result[:status]] += 1
      end

      counts
    end
  end
end
