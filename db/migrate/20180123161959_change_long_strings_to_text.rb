class ChangeLongStringsToText < ActiveRecord::Migration
  def change
    change_column_default :orgs, :links, nil
    change_column :orgs, :links, :text
    change_column_default :templates, :links, nil
    change_column :templates, :links, :text
    change_column :identifier_schemes, :logo_url, :text
    change_column :identifier_schemes, :user_landing_url, :text
  end
end
