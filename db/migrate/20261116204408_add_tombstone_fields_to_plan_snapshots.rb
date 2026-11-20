class AddTombstoneFieldsToPlanSnapshots < ActiveRecord::Migration[6.1]
  def change
    add_column :plan_snapshots, :tombstoned_at, :datetime
    add_column :plan_snapshots, :removal_reason, :string
  end
end
