class RemoveOrganisationallyVisibleFromPlanSnapshots < ActiveRecord::Migration[6.1]
  def up
    execute <<~SQL.squish
      UPDATE plan_snapshots SET visibility = 0 WHERE visibility = 1;
    SQL
  end

  def down
    # No-op: previously remapped snapshots cannot be automatically reverted
  end
end
