# frozen_string_literal: true

# Helpers for generating usage statistics
module OrgDateRangeable
  def monthly_range(org:, start_date: nil, end_date: Date.today.end_of_month, filtered: false)
    query_string = 'filtered = :filtered'
    query_hash = { filtered: filtered }
    unless org.nil?
      query_string += ' and org_id = :org_id'
      query_hash[:org_id] = org.id
    end

    unless start_date.nil?
      query_string += ' and date >= :start_date'
      query_hash[:start_date] = start_date
    end

    unless end_date.nil?
      query_string += ' and date <= :end_date'
      query_hash[:end_date] = end_date
    end
    where(query_string, query_hash)
  end

  class << self
    def split_months_from_creation(org, &block)
      starts_at = org.created_at
      ends_at = starts_at.end_of_month
      enumerable = []

      until starts_at.future? || ends_at.future?
        yield(starts_at, ends_at) if block
        enumerable << { start_date: starts_at, end_date: ends_at }
        starts_at = starts_at.next_month.beginning_of_month
        ends_at = starts_at.end_of_month
      end

      enumerable
    end
  end
end
