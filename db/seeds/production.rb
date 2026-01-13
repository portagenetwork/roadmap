#!/usr/bin/env ruby
# encoding: utf-8
# frozen_string_literal: true
# warn_indent: true

########## For sandbox overlay only
# Steps:
# 1) Using a db in a desired state, run `rails export_production_data:build_sandbox_data`
#    - This will generate new seed data in db/seeds/production/
#    - (Note: This step can be completeled locally via a db dump and committing the seed files to git)
# 2) Execute `bin/rails db:setup` against the sandbox overlay (creates the DB and seeds it)
#    - Note: the "sandbox" overlay runs with `RAILS_ENV=production`;
#      DO NOT execute `bin/rails db:setup` against any non-sandbox overlays!!!
#    - Note: This file is only used during step 2
##########
# Forcing load seed file in sequence by last number
# seeds_1 to seeds_3 are rake-generated. Other seeds file are manually edited
########## Uncomment following if we need to redo sandbox data injection
puts 'run seeds.rb file now...'
Dir[File.join(Rails.root, 'db', 'seeds', 'production', '*.rb')].sort.each_with_index do |seed, index|
    if seed.include? index.to_s
        load seed
    end
end
