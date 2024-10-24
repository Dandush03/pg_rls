# frozen_string_literal: true

require "test_helper"
require "active_record"

module PgRls
  module ActiveRecord
    module ConnectionAdapters
      module PostgreSQL
        class SqlHelperMethodTest < ::ActiveSupport::TestCase
          class TestClass
            include SqlHelperMethod

            attr_reader :execute_count

            def suppress_warning
              previous_stderr = $stderr
              $stderr = StringIO.new
              yield
              $stderr = previous_stderr
            end

            def initialize
              @execute_count = 0
            end

            def execute(_sql)
              @execute_count += 1
              raise StandardError, "PG::InFailedSqlTransaction" if @execute_count == 1
              raise StandardError, "PG::TRDeadlockDetected" if @execute_count == 2

              "Success"
            end

            def transaction
              yield
            end

            def sanitize_sql(sql)
              sql
            end
          end

          setup do
            @test_instance = TestClass.new
            @connection = ::ActiveRecord::Base.connection
          end

          test "execute_sql! retries on PG::InFailedSqlTransaction" do
            result = @connection.stub(:rollback_db_transaction, nil) do
              @test_instance.send(:execute_sql!, "SELECT 1")
            end

            assert_equal "Success", result
            assert_equal 3, @test_instance.execute_count
          end

          test "execute_sql! retries on PG::TRDeadlockDetected" do
            result = @connection.stub(:rollback_db_transaction, nil) do
              @test_instance.send(:execute_sql!, "SELECT 1")
            end

            assert_equal "Success", result
            assert_equal 3, @test_instance.execute_count
          end

          test "execute_sql! raises other errors" do
            def @test_instance.execute(_sql)
              raise StandardError, "Some other error"
            end

            assert_raises StandardError do
              @test_instance.send(:execute_sql!, "SELECT 1")
            end
          end

          test "rescue_sql_error? returns true for PG::InFailedSqlTransaction" do
            error = StandardError.new("PG::InFailedSqlTransaction")
            assert @test_instance.send(:rescue_sql_error?, error)
          end

          test "rescue_sql_error? returns true for PG::TRDeadlockDetected" do
            error = StandardError.new("PG::TRDeadlockDetected")
            assert @test_instance.send(:rescue_sql_error?, error)
          end

          test "rescue_sql_error? returns false for other errors" do
            error = StandardError.new("Some other error")
            refute @test_instance.send(:rescue_sql_error?, error)
          end
        end
      end
    end
  end
end
