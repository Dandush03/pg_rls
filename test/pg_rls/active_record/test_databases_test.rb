# frozen_string_literal: true

require "test_helper"

module PgRls
  module ActiveRecord
    class TestDatabasesTest < ::ActiveSupport::TestCase
      # What Rails does for a parallel worker — create its database and load the schema — is Rails's, and stands in
      # here as nothing: what is under test is only that the RLS configurations follow the worker's database name.
      class WorkerDatabases
        def create_and_load_schema(_index, env_name:); end
      end

      setup do
        @configs = PgRls::Record.configurations.configs_for(env_name: "test", include_hidden: true)
        @named = @configs.to_h { |config| [config, config.database] }
      end

      teardown do
        @named.each { |config, database| config._database = database }
      end

      test "a worker's RLS databases are named after it, and the primary is left to Rails" do
        WorkerDatabases.new.extend(PgRls::ActiveRecord::TestDatabases).create_and_load_schema(3, env_name: "test")

        renamed = @configs.reject { |config| config.name == "primary" }

        assert_not_empty renamed
        renamed.each { |config| assert_equal "#{@named[config]}-3", config.database }
        @configs.select { |config| config.name == "primary" }.each do |config|
          assert_equal @named[config], config.database
        end
      end
    end
  end
end
