# frozen_string_literal: true

module Orgs
  # Invoked by the `orgs:delete_orphan_orgs` rake task.
  # Deletes all orphan orgs from the db
  module DeleteOrphanOrgsService
    require 'csv'

    DRY_RUN_CSV = Rails.root.join('tmp', 'orphan_orgs.csv')
    DELETED_CSV = Rails.root.join('tmp', 'deleted_orphan_orgs.csv')

    extend self

    def run(dry_run: false)
      orphan_orgs = Orgs::AssociationInspector.orphan_orgs

      puts "Found #{orphan_orgs.size} orphan orgs"

      if dry_run
        write_dry_run_to_csv(orphan_orgs)
      else
        results = handle_deletion_of_orgs(orphan_orgs)
        write_deleted_to_csv(results)
      end
    end

    private

    def handle_deletion_of_orgs(orgs)
      results = []

      orgs.find_each do |org|
        org.destroy!
        results << { id: org.id, name: org.name, deletion_outcome: 'success' }
      rescue ActiveRecord::RecordNotDestroyed => e
        results << { id: org.id, name: org.name, deletion_outcome: 'failure', error: e.message }
        puts "Failed to destroy Org #{org.id}: #{e.message}"
      end

      results
    end

    def write_dry_run_to_csv(orgs)
      CSV.open(DRY_RUN_CSV, 'w') do |csv|
        csv << %w[id name]
        orgs.find_each do |org|
          csv << [org.id, org.name]
        end
      end
      puts "CSV written to #{DRY_RUN_CSV}"
    end

    def write_deleted_to_csv(results)
      CSV.open(DELETED_CSV, 'w') do |csv|
        csv << %w[id name deletion_outcome error]
        results.each do |row|
          csv << [row[:id], row[:name], row[:deletion_outcome], row[:error]]
        end
      end
      puts "CSV written to #{DELETED_CSV}"
    end
  end
end
