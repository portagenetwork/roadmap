# frozen_string_literal: true

namespace :datacite do
  desc 'Add or update the DataCite IdentifierScheme'
  task add_identifier_scheme: :environment do
    scheme = IdentifierScheme.find_or_create_by!(name: 'datacite') do |s|
      s.description = 'DataCite DOI service'
      s.active = true
      s.identifier_prefix = 'https://doi.org/'
    end

    puts "DataCite IdentifierScheme verified (ID: #{scheme.id})"
  end
end
