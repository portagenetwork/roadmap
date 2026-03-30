class AddUserToOauthApplications < ActiveRecord::Migration[6.1]
  def up
    add_reference :oauth_applications, :user, foreign_key: true, index: true

    # Backfill all existing records
    Doorkeeper::Application.update_all(user_id: 1)

    # Enforce NOT NULL after backfill
    change_column_null :oauth_applications, :user_id, false
  end

  def down
    remove_reference :oauth_applications, :user, foreign_key: true
  end
end
