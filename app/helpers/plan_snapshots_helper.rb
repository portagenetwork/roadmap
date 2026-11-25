# frozen_string_literal: true

# View helpers for rendering PlanSnapshot metadata on landing and tombstone pages
module PlanSnapshotsHelper
  def snapshot_display_title(snapshot)
    snapshot.title.presence
  end

  def snapshot_contributor_names(snapshot)
    snapshot.contributors.filter_map { |contributor| contributor.name.presence }
  end

  def snapshot_organization_names(snapshot, plan)
    org_names = snapshot.contributors.filter_map do |contributor|
      contributor.affiliation&.name.presence
    end

    ([plan&.org&.name.presence] + org_names).compact.uniq
  end
end
