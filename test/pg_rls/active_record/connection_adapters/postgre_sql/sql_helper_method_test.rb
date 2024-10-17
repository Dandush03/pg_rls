# frozen_string_literal: true

require "test_helper"

module PgRls
  module ActiveRecord
    module ConnectionAdapters
      module PostgreSQL
        class SqlHelperMethodTest < ::ActiveSupport::TestCase
          test "executes the SQL statement" do
            connection = Minitest::Mock.new
            connection.expect(:execute, true, ["SELECT 1 FROM pg_catalog.pg_roles WHERE rolname = 'test_app_user';"])

            result = connection.execute("SELECT 1 FROM pg_catalog.pg_roles WHERE rolname = 'test_app_user';")

            assert_equal(true, result)

            connection.verify
          end
        end
      end
    end
  end
end
