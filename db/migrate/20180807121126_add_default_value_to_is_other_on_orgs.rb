class AddDefaultValueToIsOtherOnOrgs < ActiveRecord::Migration
  def up
    change_column :orgs, :is_other, :boolean, default: false, null: false
  end
  def down
    change_column :orgs, :is_other, :boolean, default: nil, null: true
  end
end
