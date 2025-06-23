# frozen_string_literal: true

require "test_helper"

module PgRls
  module ActiveRecord
    module ConnectionAdapters
      module PostgreSQL
        class GrantRlsUserPrivilegesTest < ::ActiveSupport::TestCase
          attr_reader :connection

          setup do
            @connection = ::ActiveRecord::Base.connection
            PgRls.username = "test_app_user"
            PgRls.rls_role_group = "rls_test_group"

            connection.create_rls_group("rls_test_group")
            connection.create_rls_role("test_app_user", "test_app_password")
          end

          teardown do
            connection.drop_rls_user("test_app_user")
            connection.revoke_rls_user_privileges("public")
            connection.drop_rls_group("rls_test_group")
            connection.drop_table(:test_table, if_exists: true)
            PgRls.reset_config!
          end

          class GrantRlsUserPrivilegesTest < self
            test "grants user privileges" do
              assert_nothing_raised do
                connection.grant_rls_user_privileges("public")
              end
            end

            test "grant usage on schema" do
              connection.grant_rls_user_privileges("public")

              assert connection.send(:check_schema_usage_privilege!, "rls_test_group", "public")
            end

            test "grant default sequence privileges" do
              connection.grant_rls_user_privileges("public")

              assert connection.send(:check_default_sequence_privileges!, "rls_test_group", "public")
            end

            test "grant default table privileges" do
              connection.grant_rls_user_privileges("public")

              assert connection.send(:check_default_table_privileges!, "rls_test_group", "public")
            end

            test "grant existing table privileges" do
              connection.create_table(:test_table)
              connection.grant_rls_user_privileges("public")

              assert connection.send(:check_table_privileges!, "rls_test_group", "public", "test_table")
            end

            test "grant existing sequence privileges" do
              connection.create_table(:test_table)
              connection.grant_rls_user_privileges("public")

              assert connection.send(:check_sequence_privileges!, "rls_test_group", "public", "test_table_id_seq")
            end
          end

          class RevokeRlsUserPrivilegesTest < self
            setup do
              connection.create_table(:test_table)
              connection.grant_rls_user_privileges("public")
            end

            test "revokes user privileges" do
              assert_nothing_raised do
                connection.revoke_rls_user_privileges("public")
              end
            end

            test "revoke table migrations privileges" do
              connection.revoke_rls_user_privileges("public")

              assert_raises(UserMissingTablePrivilegesError) do
                connection.send(:check_table_privileges!, "rls_test_group", "public", "schema_migrations")
              end
            end

            test "revoke usage on schema" do
              connection.revoke_rls_user_privileges("public")

              assert_raises(UserMissingSchemaUsagePrivilegeError) do
                connection.send(:check_schema_usage_privilege!, "rls_test_group", "public")
              end
            end

            test "revoke default sequence privileges" do
              connection.revoke_rls_user_privileges("public")

              assert_raises(UserMissingSequencePrivilegesError) do
                connection.send(:check_default_sequence_privileges!, "rls_test_group", "public")
              end
            end

            test "revoke default table privileges" do
              connection.revoke_rls_user_privileges("public")

              assert_raises(UserMissingTablePrivilegesError) do
                connection.send(:check_default_table_privileges!, "rls_test_group", "public")
              end
            end

            test "revoke existing table privileges" do
              connection.revoke_rls_user_privileges("public")

              assert_raises(UserMissingTablePrivilegesError) do
                connection.send(:check_table_privileges!, "rls_test_group", "public", "test_table")
              end
            end

            test "revoke existing sequence privileges" do
              connection.revoke_rls_user_privileges("public")

              assert_raises(UserMissingSequencePrivilegesError) do
                connection.send(:check_sequence_privileges!, "rls_test_group", "public", "test_table_id_seq")
              end
            end
          end
        end
      end
    end
  end
end
