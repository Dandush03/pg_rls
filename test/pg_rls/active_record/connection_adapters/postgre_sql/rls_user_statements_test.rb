# frozen_string_literal: true

require "test_helper"

module PgRls
  module ActiveRecord
    module ConnectionAdapters
      module PostgreSQL
        class RlsUserStatementsTest < ::ActiveSupport::TestCase
          attr_reader :connection

          setup do
            @connection = ::ActiveRecord::Base.connection
            PgRls.username = "test_app_user"
            PgRls.rls_role_group = "rls_test_group"
          end

          teardown do
            PgRls.reset_config!
          end

          class CreateRlsRoleTest < self
            setup do
              connection.create_rls_group("rls_test_group")
            end

            teardown do
              connection.drop_rls_role("test_app_user")
              connection.drop_rls_group("rls_test_group")
            end

            test "creates the role" do
              connection.create_rls_role("test_app_user", "password")

              assert connection.user_exists?("test_app_user")
            end

            test "assigns the user to the group" do
              connection.create_rls_role("test_app_user", "password")

              assert connection.send(:check_user_in_rls_group!, "test_app_user")
            end

            test "creates the role rls_group" do
              connection.create_rls_role("test_app_user", "password")

              assert connection.user_exists?("rls_test_group")
            end
          end

          class UserExistsTest < self
            test "checks if the user exists" do
              connection.create_rls_user("test_app_user", "password")

              assert connection.user_exists?("test_app_user")
            end
          end

          class CreateRlsGroupTest < self
            test "creates the group" do
              connection.create_rls_group("rls_test_group")

              assert connection.user_exists?("rls_test_group")
            end
          end

          class AssignUserToGroupTest < self
            test "assigns the user to the group" do
              connection.create_rls_group("rls_test_group")
              connection.create_rls_user("test_app_user", "password")
              connection.assign_user_to_group("test_app_user")

              assert connection.send(:check_user_in_rls_group!, "test_app_user")
            end
          end

          class CreateRlsUserTest < self
            test "creates the user" do
              connection.create_rls_user("test_app_user", "password")

              assert connection.user_exists?("test_app_user")
            end
          end

          class DropRlsRoleTest < self
            setup do
              connection.create_rls_group("rls_test_group")
              connection.create_rls_role("test_app_user", "password")
            end

            test "removes the user from the group" do
              connection.drop_rls_role("test_app_user")

              assert_raises(PgRls::ActiveRecord::ConnectionAdapters::PostgreSQL::UserNotInPgRlsGroupError) do
                connection.send(:check_user_in_rls_group!, "test_app_user")
              end
            end

            test "drops the user" do
              connection.drop_rls_role("test_app_user")

              refute connection.user_exists?("test_app_user")
            end

            test "does not drops the group" do
              connection.drop_rls_role("test_app_user")

              assert connection.user_exists?("rls_test_group")
            end
          end

          class DropRlsUserTest < self
            setup do
              connection.create_rls_user("test_app_user", "password")
            end

            test "drops the user" do
              connection.drop_rls_user("test_app_user")

              refute connection.user_exists?("test_app_user")
            end
          end

          class DropRlsGroupTest < self
            setup do
              connection.create_rls_group("rls_test_group")
            end

            test "drops the group" do
              connection.drop_rls_group("rls_test_group")

              refute connection.user_exists?("rls_test_group")
            end
          end

          class RemoveUserFromGroupTest < self
            setup do
              connection.create_rls_group("rls_test_group")
              connection.create_rls_user("test_app_user", "password")
              connection.assign_user_to_group("test_app_user")
            end

            teardown do
              connection.drop_rls_role("test_app_user")
              connection.drop_rls_group("rls_test_group")
            end

            test "removes the user from the group" do
              connection.remove_user_from_group("test_app_user")

              assert_raises(PgRls::ActiveRecord::ConnectionAdapters::PostgreSQL::UserNotInPgRlsGroupError) do
                connection.send(:check_user_in_rls_group!, "test_app_user")
              end
            end
          end
        end
      end
    end
  end
end
