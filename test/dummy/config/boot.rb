# frozen_string_literal: true

require "bundler/setup" # Set up gems listed in the Gemfile.
require "bootsnap/setup" # Speed up boot time by caching expensive operations.

$LOAD_PATH.unshift File.expand_path(ENV.fetch("LIB_DIR", nil))
