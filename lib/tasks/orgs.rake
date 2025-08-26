# frozen_string_literal: true

namespace :orgs do
  desc 'retrieves ROR ids for each of the Orgs defined in the database'
  task retrieve_ror_fundref_ids: :environment do
    ror = IdentifierScheme.find_by(name: 'ror')
    fundref = IdentifierScheme.find_by(name: 'fundref')

    out = CSV.generate do |csv|
      csv << %w[org_id org_name ror_name ror_id fundref_id]

      if ExternalApis::RorService.ping
        # rubocop:disable Layout/LineLength
        p 'Scanning ROR for each of your existing Orgs'
        p 'The results will be written to tmp/ror_fundref_ids.csv to facilitate review and any corrections that may need to be made.'
        p 'The CSV file contains the Org name stored in your DB next to the ROR org name that was matched. Use these 2 values to determine if the match was valid.'
        p 'You can use the ROR search page to find the correct match for any organizations that need to be corrected: https://ror.org/search'
        p ''
        # rubocop:enable Layout/LineLength
        orgs = Org.includes(identifiers: :identifier_scheme)
                  .where(is_other: false).order(:name)

        orgs.each do |org|
          # If the Org already has a ROR identifier skip it
          next if org.identifiers.any? { |id| id.identifier_scheme_id == ror.id }

          # The abbreviation sometimes causes weird results so strip it off
          # in this instance
          org_name = org.name.gsub(" (#{org.abbreviation})", '')
          rslts = OrgSelection::SearchService.search_externally(search_term: org_name)
          next unless rslts.any?

          # Just use the first match that contains the search term
          rslt = rslts.find { |r| r[:weight] <= 1 }
          next unless rslt.present?

          ror_id = rslt[:ror]
          fundref_id = rslt[:fundref]

          if ror_id.present?
            ror_ident = Identifier.find_or_initialize_by(identifiable: org,
                                                         identifier_scheme: ror)
            ror_ident.value = "#{ror.identifier_prefix}#{ror_id}"
            ror_ident.save
            p "    #{org.name} -> ROR: #{ror_ident.value}, #{rslt[:name]}"
          end
          if fundref_id.present?
            fr_ident = Identifier.find_or_initialize_by(identifiable: org,
                                                        identifier_scheme: fundref)
            fr_ident.value = "#{fundref.identifier_prefix}#{fundref_id}"
            fr_ident.save
            p "    #{org.name} -> FUNDRF: #{fr_ident.value}, #{rslt[:name]}"
          end

          if ror_id.present? || fundref_id.present?
            csv << [org.id, org.name, rslt[:name], ror_ident&.value, fr_ident&.value]
          end
        end
      else
        # rubocop:disable Layout/LineLength
        p 'ROR appears to be offline or your configuration is invalid. Heartbeat check failed. Refer to the log for more information.'
        # rubocop:enable Layout/LineLength
      end
    end

    if out.present?
      file = File.open('tmp/ror_fundref_ids.csv', 'w')
      file.puts out
      file.close
    end
  end
end
