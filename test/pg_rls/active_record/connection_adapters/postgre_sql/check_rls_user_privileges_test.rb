# frozen_string_literal: true

require "test_helper"

module PgRls
  module ActiveRecord
    module ConnectionAdapters
      module PostgreSQL
        class CheckRlsUserPrivilegesTest < ::ActiveSupport::TestCase
          attr_reader :connection

          setup do
            @connection = ::ActiveRecord::Base.connection
            connection.create_rls_group
            connection.create_rls_role("test_app_user", "test_app_password")
          end

          teardown do
            connection.revoke_rls_user_privileges("public") if connection.user_exists?("test_app_user")
            connection.drop_rls_role("test_app_user")
            connection.drop_rls_group
            connection.drop_table(:test_table, if_exists: true)
          end

          class CheckRlsUserPrivilegesTest < self
            test "checks the user privileges" do
              connection.grant_rls_user_privileges("public")

              assert connection.send(:check_rls_user_privileges!, "test_app_user", "public")
            end

            test "raises an PgRls::Error if the user does not exist" do
              connection.revoke_rls_user_privileges("public")

              assert_raises(PgRls::Error) do
                connection.send(:check_rls_user_privileges!, "test_app_user", "public")
              end
            end
          end

          class CheckUserExistsTest < self
            test "checks if the user exists" do
              assert connection.send(:check_user_exists!, "test_app_user")
            end

            test "raises an error if the user does not exist" do
              connection.drop_rls_user("test_app_user")

              assert_raises(PgRls::ActiveRecord::ConnectionAdapters::PostgreSQL::UserDoesNotExistError) do
                connection.send(:check_user_exists!, "test_app_user")
              end
            end
          end

          class CheckUserInRlsGroupTest < self
            test "checks if the user is in the rls_group" do
              assert connection.send(:check_user_in_rls_group!, "test_app_user")
            end

            test "raises an error if the user is not in the rls_group" do
              connection.remove_user_from_group("test_app_user")

              assert_raises(PgRls::ActiveRecord::ConnectionAdapters::PostgreSQL::UserNotInPgRlsGroupError) do
                connection.send(:check_user_in_rls_group!, "test_app_user")
              end
            end
          end

          class CheckSchemaUsagePrivilegeTest < self
            test "checks the user schema usage privileges" do
              connection.grant_rls_user_privileges("public")

              assert connection.send(:check_schema_usage_privilege!, "rls_group", "public")
            end

            test "raises an error if the user does not have the schema usage privileges" do
              assert_raises(UserMissingSchemaUsagePrivilegeError) do
                connection.send(:check_schema_usage_privilege!, "rls_group", "public")
              end
            end
          end

          class CheckDefaultTablePrivilegesTest < self
            test "checks the user default table privileges" do
              connection.grant_rls_user_privileges("public")

              assert connection.send(:check_default_table_privileges!, "rls_group", "public")
            end

            test "raises an error if the user does not have the default table privileges" do
              assert_raises(UserMissingTablePrivilegesError) do
                connection.send(:check_default_table_privileges!, "rls_group", "public")
              end
            end
          end

          class CheckTablePrivilegesTest < self
            test "checks the user table privileges" do
              connection.grant_rls_user_privileges("public")
              connection.create_table(:test_table)

              assert connection.send(:check_table_privileges!, "rls_group", "public", "test_table")
            end

            test "raises an error if the user does not have the table privileges" do
              assert_raises(UserMissingTablePrivilegesError) do
                connection.send(:check_table_privileges!, "rls_group", "public", "test_table")
              end
            end
          end

          class CheckDefaultSequencePrivilegesTest < self
            test "checks the user default sequence privileges" do
              connection.grant_rls_user_privileges("public")

              assert connection.send(:check_default_sequence_privileges!, "rls_group", "public")
            end

            test "raises an error if the user does not have the default sequence privileges" do
              assert_raises(UserMissingSequencePrivilegesError) do
                connection.send(:check_default_sequence_privileges!, "rls_group", "public")
              end
            end
          end

          class CheckSequencePrivilegesTest < self
            test "checks the user sequence privileges" do
              connection.grant_rls_user_privileges("public")
              connection.create_table(:test_table)

              assert connection.send(:check_sequence_privileges!, "rls_group", "public", "test_table_id_seq")
            end

            test "raises an error if the user does not have the sequence privileges" do
              assert_raises(UserMissingSequencePrivilegesError) do
                connection.send(:check_sequence_privileges!, "rls_group", "public", "test_table_id_seq")
              end
            end
          end

          class CheckTableRlsEnabledTest < self
            setup do
              connection.create_table(:test_table) { |t| t.uuid :tenant_id }
            end

            teardown do
              connection.disable_table_rls("test_table", "public")
              connection.drop_table(:test_table, if_exists: true)
            end

            test "checks if the table rls is enabled" do
              connection.enable_table_rls("test_table", "public")

              assert connection.check_table_rls_enabled!("test_table")
            end

            test "raises an error if the table rls is not enabled" do
              assert_raises(TableRlsNotEnabledError) do
                connection.check_table_rls_enabled!("test_table")
              end
            end
          end

          class CheckTableRlsDisabledTest < self
            setup do
              connection.create_table(:test_table) { |t| t.uuid :tenant_id }
            end

            teardown do
              connection.disable_table_rls("test_table", "public")
              connection.drop_table(:test_table, if_exists: true)
            end

            test "checks if the table user policy exists" do
              connection.enable_table_rls("test_table", "public")

              assert connection.check_table_user_policy_exists!("test_table", "public")
            end

            test "raises an error if the table user policy does not exist" do
              assert_raises(TableUserPolicyDoesNotExistError) do
                connection.check_table_user_policy_exists!("test_table", "test_app_user")
              end
            end
          end
        end
      end
    end
  end
end
