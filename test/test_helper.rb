# frozen_string_literal: true

# Configure Rails Environment
ENV["RAILS_ENV"] = "test"
ENV["BUNDLE_GEMFILE"] = File.expand_path("../Gemfile", __dir__)
ENV["LIB_DIR"] = File.expand_path("../lib", __dir__)

require_relative "test_helpers/simplecov"

require_relative "dummy/config/environment"
require "pg_rls"
require "pg_rls/active_record/test_databases"

ActiveRecord::Migrator.migrations_paths = [File.expand_path(
  "dummy/db/migrate", __dir__
)]
require "rails/test_help"
require "minitest/autorun"

# Load fixtures from the engine
if ActiveSupport::TestCase.respond_to?(:fixture_paths=)
  ActiveSupport::TestCase.fixture_paths =
    [File.expand_path("fixtures", __dir__), File.expand_path("dummy/test/fixtures", __dir__)]
  ActionDispatch::IntegrationTest.fixture_paths =
    ActiveSupport::TestCase.fixture_paths
  ActiveSupport::TestCase.file_fixture_path =
    "#{File.expand_path("fixtures", __dir__)}/files"
end

module ActiveSupport
  class TestCase
    workers = RUBY_PLATFORM.include?("darwin") ? 1 : :number_of_processors

    parallelize(workers: workers)

    parallelize_setup do |worker|
      SimpleCov.command_name "Worker-#{worker}" if const_defined?(:SimpleCov)
      DatabaseCleaner.strategy = :transaction
      DatabaseCleaner.clean_with(:truncation)
      setup_pg_rls if respond_to?(:setup_pg_rls)
    end

    parallelize_teardown do |_worker|
      SimpleCov.result if const_defined?(:SimpleCov)
    end

    setup do
      DatabaseCleaner.start
      self.class.setup_pg_rls
    end

    teardown do
      DatabaseCleaner.clean
      PgRls.reset_config!
    end

    def self.setup_pg_rls
      PgRls.class_name = :Tenant
      PgRls.table_name = :tenants
      PgRls.search_methods = %i[subdomain tenant_id id]
      PgRls.current_attributes = %i[post]
    end
  end
end
