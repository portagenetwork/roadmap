class ChangeColumnNullUserLanguageIds < ActiveRecord::Migration[5.2]
  def change
    User.where(language_id: nil).each do |user|
      begin
        # First try setting user's language_id to that of their org
        user.language_id = Org.find(user.org_id).language_id
        user.save!
      rescue StandardError
        # Rescue with the app's default language.
        user.language_id = Language.default&.id
        user.save
      end
    end
  # Finally, set NOT NULL constraint on User.language_id
  change_column_null :users, :language_id, false
  end
end
