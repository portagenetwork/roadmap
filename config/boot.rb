# frozen_string_literal: true

ENV["BUNDLE_GEMFILE"] ||= File.expand_path("../Gemfile", __dir__)

<<<<<<< HEAD
require "bundler/setup" # Set up gems listed in the Gemfile.
# require "bootsnap/setup" # Speed up boot time by caching expensive operations.
=======
require 'bundler/setup' # Set up gems listed in the Gemfile.
# Load Logger before Rails boot rather than relying on a transitive require.
require 'logger'
require 'bootsnap/setup' # Speed up boot time by caching expensive operations.
>>>>>>> ff3c4241c (Upgrade/ruby 3.4 rails 8.1 (#3624))
