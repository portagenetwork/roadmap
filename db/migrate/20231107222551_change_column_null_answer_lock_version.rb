class ChangeColumnNullAnswerLockVersion < ActiveRecord::Migration[5.2]
  def change
    # Change all nil Answer.lock_version values to 0 and then disallow nil values
    change_column_null(:answers, :lock_version, false, 0)
  end
end
