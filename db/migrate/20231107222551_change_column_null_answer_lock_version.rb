class ChangeColumnNullAnswerLockVersion < ActiveRecord::Migration[5.2]
  def change
    # change_column_null(table_name, column_name, null, default = nil) The null flag indicates whether the value can be NULL
    change_column_null(:answers, :lock_version, false, 0)
  end
end
