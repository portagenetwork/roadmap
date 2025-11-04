# frozen_string_literal: true

namespace :orgs do
  desc 'Updates DB and Creates CSV with Org-related ROR/Fundref data'
  task update_ror_data: :environment do
    # By default, existing ROR/Fundref data is not updated.
    # - To update existing data, prepend `UPDATE_EXISTING=true`
    #   - (e.g. `UPDATE_EXISTING=true bundle exec rake orgs:update_ror_data`)
    update_existing = ENV['UPDATE_EXISTING'] == 'true'
    Orgs::UpdateRorService.run(update_existing: update_existing)
  end
end
