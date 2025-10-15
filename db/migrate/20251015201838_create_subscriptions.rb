class CreateSubscriptions < ActiveRecord::Migration[6.1]
  def change
    create_table :subscriptions do |t|
      t.references :plan, foreign_key: true, index: true
      t.integer :subscription_types, null: false
      t.string :callback_uri
      t.bigint :subscriber_id
      t.string :subscriber_type
      t.datetime :last_notified, index: true
      t.timestamps
    end

    add_index :subscriptions, [:subscriber_id, :subscriber_type, :plan_id], name: "index_subscribers_on_identifiable_and_plan_id"
  end
end
