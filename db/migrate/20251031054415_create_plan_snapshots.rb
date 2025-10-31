class CreatePlanSnapshots < ActiveRecord::Migration[6.1]
  def change
    create_table :plan_snapshots do |t|
      t.references :plan, null: false, foreign_key: true
      t.integer :version, null: false
      t.integer :visibility, null: false, default: 0
      t.jsonb :rda_json, null: false
      t.jsonb :additional_json
      t.timestamps
    end

    add_index :plan_snapshots, [:plan_id, :version], unique: true

    # Prevent saving of invalid visibility values directly to the db
    execute <<-SQL
      ALTER TABLE plan_snapshots
      ADD CONSTRAINT visibility_check
      CHECK (visibility IN (0, 1, 2))
    SQL
  end
end
