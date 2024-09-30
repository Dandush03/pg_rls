# frozen_string_literal: true

require_relative "helpers/simplecov"
require_relative "helpers/database_connection"
require "pg_rls"

RSpec.configure do |config|
  PgRls::DatabaseConnection.establish_connection!

  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = ".rspec_status"

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end
end
