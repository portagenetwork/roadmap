class SetLanguageIdNotNullOnUsers < ActiveRecord::Migration[6.1]

  def up
    # Ensure default language exists before applying the changes
    default_language_id = handle_default_language_id
    # Disallow null values for user.language_id
    # Also, set all currently null user.language_id values to the app's default language_id
    change_column_null :users, :language_id, false, default_language_id
  end

  def down
    # Allow null values for user.language_id
    change_column_null :users, :language_id, true
  end

  private

    # Return Language.default.id or raise an exception if not found, causing the migration to fail
    def handle_default_language_id
      default_language = Language.default
  
      if default_language.nil?
        Rails.logger.error 'Error: Language.default not found. Please ensure the default language is set.'
        message = 'Migration aborted: No database changes were performed due to missing Language.default.'
        raise StandardError, message
      end
      default_language.id
    end
end
