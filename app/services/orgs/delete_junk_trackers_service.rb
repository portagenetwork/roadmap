# frozen_string_literal: true

module Orgs
  # Invoked by the `orgs:delete_junk_trackers` Rake task.
  # This service deletes all "junk" trackers (i.e. `Tracker.where(code: '')`)
  # Partly addresses https://github.com/portagenetwork/roadmap/issues/1260
  module DeleteJunkTrackersService
    module_function

    def run
      junk_trackers = Tracker.where(code: '')
      puts "Found #{junk_trackers.count} junk trackers ( i.e. `Tracker.where(code: '')` )"
      destroy_result = junk_trackers.destroy_all
      puts "Deleted #{destroy_result.count} of these junk trackers."
    end
  end
end
