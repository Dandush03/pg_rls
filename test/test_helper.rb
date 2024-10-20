# frozen_string_literal: true

# Configure Rails Environment
ENV["RAILS_ENV"] = "test"
ENV["BUNDLE_GEMFILE"] = File.expand_path("../Gemfile", __dir__)
ENV["LIB_DIR"] = File.expand_path("../lib", __dir__)

require_relative "test_helpers/simplecov"

require_relative "dummy/config/environment"
require "pg_rls"

ActiveRecord::Migrator.migrations_paths = [File.expand_path(
  "dummy/db/migrate", __dir__
)]
require "rails/test_help"
require "minitest/autorun"

# Load fixtures from the engine
if ActiveSupport::TestCase.respond_to?(:fixture_paths=)
  ActiveSupport::TestCase.fixture_paths =
    [File.expand_path("fixtures", __dir__)]
  ActionDispatch::IntegrationTest.fixture_paths =
    ActiveSupport::TestCase.fixture_paths
  ActiveSupport::TestCase.file_fixture_path =
    "#{File.expand_path("fixtures", __dir__)}/files"
  ActiveSupport::TestCase.fixtures :all
end

module ActiveSupport
  class TestCase
    workers = RUBY_PLATFORM.include?("darwin") ? 1 : :number_of_processors

    parallelize_setup do |_worker|
      SimpleCov.command_name "Job::#{Process.pid}" if const_defined?(:SimpleCov)
    end

    parallelize_teardown do |_worker|
      SimpleCov.result if const_defined?(:SimpleCov)
    end

    parallelize(workers: workers)

    DatabaseCleaner.strategy = :transaction

    setup do
      DatabaseCleaner.start
    end

    teardown do
      DatabaseCleaner.clean
    end
  end
end
