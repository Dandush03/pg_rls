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

      # Rails from 8.1 on names every configuration a worker uses, hidden ones too.
      class WorkerDatabasesNamingEveryOne
        def create_and_load_schema(index, env_name:)
          PgRls::Record.configurations.configs_for(env_name: env_name, include_hidden: true).each do |config|
            config._database = "#{config.database}_#{index}"
          end
        end
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

      test "a configuration Rails has already named for the worker is not named again" do
        WorkerDatabasesNamingEveryOne.new.extend(PgRls::ActiveRecord::TestDatabases)
                                     .create_and_load_schema(3, env_name: "test")

        @configs.each { |config| assert_equal "#{@named[config]}_3", config.database }
      end
    end
  end
end
