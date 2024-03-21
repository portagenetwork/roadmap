# frozen_string_literal: true

# Helper for exporting to CSV format
module Csvable
  require 'csv'
  class << self
    # rubocop:disable Style/OptionalBooleanParameter, Metrics/AbcSize
    def from_array_of_hashes(data = [], humanize = true, sep = ',')
      return '' unless data.first&.keys

      headers = if humanize
                  data.first.keys
                      .map { |x| _(x.to_s.humanize) }
                else
                  data.first.keys
                      .map { |x| _(x.to_s) }
                end

      CSV.generate({ col_sep: sep }) do |csv|
        csv << headers
        data.each do |row|
          csv << row.values
        end
      end
    end
    # rubocop:enable Style/OptionalBooleanParameter, Metrics/AbcSize
  end
end
