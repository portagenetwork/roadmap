# This migration converts YAML-serialized columns to JSON on PostgreSQL only.
class UpdateConditionsJsonColumnsData < ActiveRecord::Migration[7.1]
  # rubocop:disable Metrics/MethodLength
  def change
    if ActiveRecord::Base.connection.adapter_name.downcase.include?('mysql')
      raise 'UpdateConditionsJsonColumnsData is not supported on MySQL.'
    else
      # POSTGRES SQL
      execute <<-SQL
        UPDATE conditions
SET
    option_list = concat (
           '[',
        regexp_replace (
        regexp_replace (
            regexp_replace (
                regexp_replace (option_list, '---(\r|\n)-', '', 'g'),
                '(\r|\n)-',
                ',',
                'g'
            ),
            '\r|\n',
            '',
            'g'
        ),
        '''',
        '"',
        'g'),
        ']'
    ),
    remove_data = concat (
        '[',
        regexp_replace (
        regexp_replace (
            regexp_replace (
                regexp_replace (remove_data, '---(\r|\n)-', '', 'g'),
                '(\r|\n)-',
                ',',
                'g'
            ),
            '\r|\n',
            '',
            'g'
        ),
        '''',
        '"',
        'g'),
        ']'
    )
WHERE
    option_list LIKE '---%';
      SQL
    end
  end
  # rubocop:enable Metrics/MethodLength

  def down
    # Add rollback logic if needed
  end
end
