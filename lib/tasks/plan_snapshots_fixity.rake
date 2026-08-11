# frozen_string_literal: true

namespace :plan_snapshots do
  task fixity_checks: :environment do
    counts = PlanSnapshots::FixityCheckRunner.new.call
    counts.each do |status, count|
      puts "#{status.to_s.upcase}: #{count}"
    end
  end
end
