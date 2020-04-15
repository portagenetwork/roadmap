# frozen_string_literal: true

module DateRangeable

  extend ActiveSupport::Concern

  module ClassMethods

    # Determines whether or not the search term is a date.
    # Expecting: '[month abbreviation] [year]' e.g.('Oct 2019')
    def date_range?(term:)
      term =~ /[A-Za-z]{3}\s+[0-9]{4}/
    end

    # Search the specified field for the specified month
    def by_data_range(field, term)
      date = Date.parse("1st #{term}")
      where("#{table_name}.#{field} BETWEEN ? AND ?", date, date.end_of_month)
    end

  end

end
