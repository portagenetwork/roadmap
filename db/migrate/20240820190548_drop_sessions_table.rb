class DropSessionsTable < ActiveRecord::Migration[6.1]
  def up
    drop_table :sessions
  end

  def down
    # rollback will the execute the initial migration code written to create the sessions table
    require Rails.root.join('db/migrate/20181024120747_add_sessions_table.rb')
    AddSessionsTable.new.change
  end
end
