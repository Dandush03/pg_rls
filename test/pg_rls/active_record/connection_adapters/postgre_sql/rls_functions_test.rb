# frozen_string_literal: true

require "test_helper"

module PgRls
  module ActiveRecord
    module ConnectionAdapters
      module PostgreSQL
        class RlsFunctionsTest < ::ActiveSupport::TestCase
          attr_reader :connection

          setup do
            @connection = ::ActiveRecord::Base.connection
          end

          teardown do
            connection.drop_rls_functions
          end

          class CreateFunctionTest < self
            test "creates a function" do
              connection.send(:create_function, "function_name", "BEGIN RETURN NULL; END;")

              assert connection.send(:function_exists?, "function_name")
            end

            test "replaces the function when it already exists" do
              connection.send(:create_function, "function_name", "BEGIN RETURN NULL; END;")
              connection.send(:create_function, "function_name", "BEGIN RETURN 1; END;")

              assert connection.send(:function_exists?, "function_name")
            end

            test "updates all tables with the new function trigger" do
              connection.create_table :test_table do |t|
                t.string :name
              end

              connection.send(:create_function, "function_name", "BEGIN RETURN NULL; END;")
              assert connection.send(:function_exists?, "function_name")

              connection.send(
                :create_trigger, "public", "test_table", "trigger_name", "function_name", "BEFORE", "INSERT"
              )
              assert_nil(connection.send(:execute_sql!, "INSERT INTO test_table (name) VALUES ('test')").first)

              connection.send(:create_function, "function_name", "BEGIN RAISE EXCEPTION 'banana'; END;")
              assert_raises(::ActiveRecord::StatementInvalid) do
                connection.send(:execute_sql!, "INSERT INTO test_table (name) VALUES ('test')")
              end
            ensure
              connection.send(:drop_trigger, "public", "test_table", "trigger_name")
              connection.drop_table :test_table
              connection.send(:drop_function, "function_name")
            end
          end

          class DropFunctionTest < self
            test "drops a function" do
              connection.send(:create_function, "function_name", "BEGIN RETURN NULL; END;")
              connection.send(:drop_function, "function_name")

              assert_not connection.send(:function_exists?, "function_name")
            end

            test "does nothing when function does not exists" do
              connection.send(:drop_function, "function_name")

              assert_not connection.send(:function_exists?, "function_name")
            end
          end

          class CreateAllRlsFunctionsTest < self
            test "creates the tenant_id_setter function" do
              connection.create_rls_functions

              assert connection.send(:function_exists?, "tenant_id_setter")
            end

            test "creates the tenant_id_update_blocker function" do
              connection.create_rls_functions

              assert connection.send(:function_exists?, "tenant_id_update_blocker")
            end

            test "creates the rls_exception function" do
              connection.create_rls_functions

              assert connection.send(:function_exists?, "rls_exception")
            end
          end

          class DropAllRlsFunctionsTest < self
            test "drops the tenant_id_setter function" do
              connection.create_rls_functions
              connection.drop_rls_functions

              assert_not connection.send(:function_exists?, "tenant_id_setter")
            end

            test "drops the tenant_id_update_blocker function" do
              connection.create_rls_functions
              connection.drop_rls_functions

              assert_not connection.send(:function_exists?, "tenant_id_update_blocker")
            end

            test "drops the rls_exception function" do
              connection.create_rls_functions
              connection.drop_rls_functions

              assert_not connection.send(:function_exists?, "rls_exception")
            end
          end
        end
      end
    end
  end
end
