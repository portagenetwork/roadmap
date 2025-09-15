# frozen_string_literal: true

CSV_FILE_PATH = Rails.root.join('tmp', 'ror_fundref_ids.csv')
CSV_HEADERS = %w[org_id org_name ror_name ror_id fundref_id weight].freeze

namespace :orgs do
  desc 'Updates DB and Creates CSV with Org-related ROR/Fundref data'
  task update_ror_data: :environment do
    ror, fundref = fetch_identifier_schemes
    # Only proceed if the identifier schemes and the ROR API are all available
    return unless ror && fundref && ror_service_available?

    print_intro_message

    CSV.open(CSV_FILE_PATH, 'w', write_headers: true, headers: CSV_HEADERS) do |csv|
      org_scope.each do |org|
        # If the Org already has a ROR identifier skip it
        next if org_has_ror_identifier?(org, ror)

        results = ror_search_results_for_org(org)
        result = best_match_from_results(results) if results.any?
        if result.present?
          handle_matched_result(org, ror, fundref, result, csv)
        else
          handle_unmatched_result(org, csv)
        end
      end
    end
  end

  def fetch_identifier_schemes
    ror = IdentifierScheme.find_by(name: 'ror')
    fundref = IdentifierScheme.find_by(name: 'fundref')

    if ror.nil? || fundref.nil?
      puts "Missing IdentifierScheme(s): ror: #{ror.inspect}, fundref: #{fundref.inspect}"
      puts 'Both must exist in DB for this task to run.'
    end
    [ror, fundref]
  end

  def ror_service_available?
    ok = ExternalApis::RorService.ping
    unless ok
      puts 'ROR appears to be offline or your configuration is invalid. ' \
           'Heartbeat check failed. Refer to the log for more information.'
    end
    ok
  end

  def org_has_ror_identifier?(org, ror)
    org.identifiers.any? { |id| id.identifier_scheme_id == ror.id }
  end

  def print_intro_message
    puts <<~MSG
      Scanning ROR for each of your existing Orgs.
      The results will be written to "#{CSV_FILE_PATH}" to facilitate#{' '}
      review and any corrections that may need to be made.
      The CSV file contains the Org name stored in your DB next to the ROR org#{' '}
      name that was matched. Use these 2 values to determine if the match was valid.
      You can use the ROR search page to find the correct match for any organizations#{' '}
      that need to be corrected: https://ror.org/search

    MSG
  end

  def org_scope
    scope = Org.includes(identifiers: :identifier_scheme)
               .where(managed: true, is_other: false)
               .order(:name)
    puts "Found #{scope.size} org(s) to process."
    scope
  end

  def ror_search_results_for_org(org)
    # The abbreviation sometimes causes weird results so strip it off in this instance
    org_name = org.name.gsub(" (#{org.abbreviation})", '')
    OrgSelection::SearchService.search_externally(search_term: org_name)
  end

  def best_match_from_results(results)
    # Find the best match
    # (See OrgSelection::SearchService#weigh for how weight is calculated.)
    results.find { |r| (r[:weight]).zero? } || results.find { |r| r[:weight] == 1 }
  end

  def handle_unmatched_result(org, csv)
    puts "⚠️  No results found for Org with id: #{org.id} and name: #{org.name}"
    csv << [org.id, org.name, nil, nil, nil, nil]
  end

  def handle_matched_result(org, ror, fundref, result, csv)
    return unless result[:ror].present? || result[:fundref].present?

    # Save ROR and FUNDREF entries to DB
    identifiers = handle_identifiers(org, ror, fundref, result)
    # Add entry to generated CSV
    csv << [org.id, org.name, result[:name], identifiers[:ror]&.value, identifiers[:fundref]&.value, result[:weight]]
  end

  def handle_identifiers(org, ror, fundref, result)
    {
      ror: handle_identifier(org, ror, result[:ror], result[:name], 'ROR'),
      fundref: handle_identifier(org, fundref, result[:fundref], result[:name], 'FUNDREF')
    }
  end

  def handle_identifier(org, identifier_scheme, id, name, label)
    return unless id.present?

    identifier = Identifier.find_or_initialize_by(identifiable: org,
                                                  identifier_scheme: identifier_scheme)
    begin
      identifier.update!(value: "#{identifier_scheme.identifier_prefix}#{id}")
      puts "✅  Updated #{org.name} -> #{label}: #{identifier.value}, #{name}"
    rescue StandardError => e
      message = "❌  Failed to update #{org.name} -> #{label}: #{e.message}"
      puts message
      Rails.logger.error(message)
    end
    identifier
  end
end
