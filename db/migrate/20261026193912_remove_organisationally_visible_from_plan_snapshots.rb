# frozen_string_literal: true

class RemoveOrganisationallyVisibleFromPlanSnapshots < ActiveRecord::Migration[6.1]
  def up
    # All snapshots are expected to be private at this point;
    # normalise any that were set to organisational (1) or public (2).
    execute <<~SQL.squish
      UPDATE plan_snapshots SET visibility = 0 WHERE visibility <> 0;
    SQL

    # Update database check constraint to allow only 0 (private) and 1 (public)
    remove_check_constraint :plan_snapshots, name: 'plan_snapshots_visibility_valid'
    add_check_constraint :plan_snapshots,
                         'visibility IN (0, 1)',
                         name: 'plan_snapshots_visibility_valid'
  end

  def down
    # Revert check constraint back to original range (0..2)
    remove_check_constraint :plan_snapshots, name: 'plan_snapshots_visibility_valid'
    add_check_constraint :plan_snapshots,
                         'visibility IN (0, 1, 2)',
                         name: 'plan_snapshots_visibility_valid'
  end
end