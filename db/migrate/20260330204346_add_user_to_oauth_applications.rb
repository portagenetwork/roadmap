class AddUserToOauthApplications < ActiveRecord::Migration[6.1]

  def up
    # Initially allow null to backfill existing oauth apps
    add_reference :oauth_applications, :user, foreign_key: true, index: true, null: true

    user = User.find_by!(email: 'dittest@ualberta.ca')

    change_column_null :oauth_applications, :user_id, false, user.id
  end

  def down
    remove_reference :oauth_applications, :user, foreign_key: true
  end
end
