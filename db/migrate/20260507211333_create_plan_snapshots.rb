class CreatePlanSnapshots < ActiveRecord::Migration[6.1]
  def change
    create_table :plan_snapshots do |t|
      t.references :plan, null: false, foreign_key: true
      t.integer :version, null: false
      t.integer :visibility, null: false, default: 0
      t.jsonb :rda_json, null: false, default: {}
      t.jsonb :extension_json, null: false, default: {}
      t.string :checksum, limit: 32, null: false
      t.datetime :fixity_checked_at
      t.timestamps null: false
    end

    # Enforce unique (plan_id, version) pairs and speed up corresponding queries
    add_index :plan_snapshots, [:plan_id, :version], unique: true
    # For querying "stale" snapshots 
    add_index :plan_snapshots, :fixity_checked_at

    # Keep visibility aligned with PlanSnapshot visibility enum values (0..2).
    add_check_constraint :plan_snapshots,
                         'visibility IN (0, 1, 2)',
                         name: 'plan_snapshots_visibility_valid'

    # Ensure version numbers are positive and start at 1.
    add_check_constraint :plan_snapshots,
                         'version >= 1',
                         name: 'plan_snapshots_version_valid'
  end
end
