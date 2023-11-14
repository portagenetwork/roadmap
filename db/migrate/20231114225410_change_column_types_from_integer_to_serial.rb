class ChangeColumnTypesFromIntegerToSerial < ActiveRecord::Migration[5.2]
  def change
    change_column :annotations, :org_id, :bigint
    change_column :annotations, :question_id, :bigint
  end
end
