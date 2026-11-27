# frozen_string_literal: true

namespace :doi do
  desc 'Add or update the Doi IdentifierScheme'
  task add_identifier_scheme: :environment do
    scheme = IdentifierScheme.find_or_create_by!(name: 'doi') do |s|
      s.description = 'DOI service'
      s.active = true
      s.identifier_prefix = 'https://doi.org/'
    end

    puts "DOI IdentifierScheme verified (ID: #{scheme.id})"
  end
end
