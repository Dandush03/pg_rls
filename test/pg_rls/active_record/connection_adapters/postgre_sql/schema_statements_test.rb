# frozen_string_literal: true

require_relative "shared_example/rls_tenant_table_behavior"
require_relative "shared_example/rls_table_behavior"

require "test_helper"

# # require_relative "shared_example/rls_table"
#
module PgRls
  module ActiveRecord
    module ConnectionAdapters
      module PostgreSQL
        class SchemaStatementsTest < ::ActiveSupport::TestCase
          attr_reader :connection

          setup do
            PgRls.username = "test_app_user"
            PgRls.rls_role_group = "test_rls_group"
            @connection = ::ActiveRecord::Base.connection
          end

          teardown do
            PgRls.reset_config!
          end

          class CreateRlsTenantTableTest < self
            include RlsTenantTableBehavior

            setup do
              connection.create_rls_tenant_table(:test_table) { |t| t.string :name }
            end

            teardown do
              connection.drop_rls_tenant_table(:test_table, if_exists: true)
            end

            behaves_like_rls_tenant_table(:test_table)
          end

          class DropRlsTenantTableTest < self
            include RlsTenantTableBehavior

            setup do
              connection.create_rls_tenant_table(:test_table) { |t| t.string :name }
              connection.drop_rls_tenant_table(:test_table)
            end

            behaves_like_absence_of_rls_tenant_table(:test_table)

            test "ensure that a rls tenant table does not exist" do
              assert_not connection.table_exists?(:test_table)
            end
          end

          class ConvertToRlsTenantTableTest < self
            include RlsTenantTableBehavior

            setup do
              PgRls.username = "test_app_user"
              PgRls.rls_role_group = "test_rls_group"
              connection.create_table(:test_table) { |t| t.string :name }
              connection.convert_to_rls_tenant_table(:test_table)
            end

            teardown do
              connection.drop_table(:test_table, if_exists: true)
              PgRls.reset_config!
            end

            behaves_like_rls_tenant_table(:test_table)
          end

          class RevertFromRlsTenantTableTest < self
            include RlsTenantTableBehavior

            setup do
              connection.create_table(:test_table) { |t| t.string :name }
              connection.convert_to_rls_tenant_table(:test_table)

              connection.revert_from_rls_tenant_table(:test_table)
            end

            teardown do
              connection.drop_table(:test_table, if_exists: true)
            end

            behaves_like_absence_of_rls_tenant_table(:test_table)

            test "ensure that a rls tenant table persist" do
              assert connection.table_exists?(:test_table)
            end
          end

          class CreateRlsTableTest < self
            include RlsTableBehavior

            setup do
              connection.create_rls_tenant_table(:tenant_table) { |t| t.string :name }
              connection.create_rls_table(:test_table) { |t| t.string :name }
            end

            teardown do
              connection.drop_rls_table(:test_table, if_exists: true)
              connection.drop_rls_tenant_table(:tenant_table, if_exists: true)
            end

            behaves_like_rls_table(:test_table)

            class WhenRlsSet < self
              include RlsTableBehavior
              attr_reader :tenant_uuid

              setup do
                @tenant_uuid = SecureRandom.uuid
                connection.send(:execute_sql!, "SET rls.tenant_id = '#{tenant_uuid}'")
              end

              teardown do
                connection.send(:execute_sql!, "RESET rls.tenant_id")
              end

              rls_table_behavior_with_tenant_id(:test_table)
            end

            class WhenRlsNotSet < self
              include RlsTableBehavior

              rls_table_behavior_without_tenant_id(:test_table)
            end
          end

          class DropRlsTableTest < self
            include RlsTableBehavior

            setup do
              connection.create_rls_tenant_table(:tenant_table) { |t| t.string :name }
              connection.create_rls_table(:test_table) { |t| t.string :name }
              connection.drop_rls_table(:test_table)
            end

            teardown do
              connection.drop_rls_tenant_table(:tenant_table, if_exists: true)
            end

            behaves_like_absence_of_rls_table(:test_table)

            class WhenRlsSet < self
              include RlsTableBehavior

              attr_reader :tenant_uuid

              setup do
                @tenant_uuid = SecureRandom.uuid
                connection.send(:execute_sql!, "SET rls.tenant_id = '#{tenant_uuid}'")
              end

              teardown do
                connection.send(:execute_sql!, "RESET rls.tenant_id")
              end

              behaves_like_absence_of_rls_table_with_tenant_id(:test_table)
            end

            class WhenRlsNotSet < self
              include RlsTableBehavior

              behaves_like_absence_of_rls_table_without_tenant_id(:test_table)
            end
          end

          class ConvertToRlsTableTest < self
            include RlsTableBehavior

            setup do
              connection.create_rls_tenant_table(:tenant_table) { |t| t.string :name }
              connection.create_table(:test_table) { |t| t.string :name }
              connection.convert_to_rls_table(:test_table)
            end

            teardown do
              connection.drop_table(:test_table, if_exists: true)
              connection.drop_rls_tenant_table(:tenant_table, if_exists: true)
            end

            behaves_like_rls_table(:test_table)

            class WhenRlsSet < self
              include RlsTableBehavior

              attr_reader :tenant_uuid

              setup do
                @tenant_uuid = SecureRandom.uuid
                connection.send(:execute_sql!, "SET rls.tenant_id = '#{tenant_uuid}'")
              end

              teardown do
                connection.send(:execute_sql!, "RESET rls.tenant_id")
              end

              rls_table_behavior_with_tenant_id(:test_table)
            end

            class WhenRlsNotSet < self
              include RlsTableBehavior

              rls_table_behavior_without_tenant_id(:test_table)
            end
          end

          class RevertFromRlsTableTest < self
            include RlsTableBehavior

            setup do
              connection.create_rls_tenant_table(:tenant_table) { |t| t.string :name }
              connection.create_table(:test_table) { |t| t.string :name }
              connection.convert_to_rls_table(:test_table)

              connection.revert_from_rls_table(:test_table)
            end

            teardown do
              connection.drop_table(:test_table, if_exists: true)
              connection.drop_rls_tenant_table(:tenant_table, if_exists: true)
            end

            behaves_like_absence_of_rls_table(:test_table)

            test "ensure that a rls table persist" do
              assert connection.table_exists?(:test_table)
            end

            class WhenRlsSet < self
              include RlsTableBehavior

              attr_reader :tenant_uuid

              setup do
                @tenant_uuid = SecureRandom.uuid
                connection.send(:execute_sql!, "SET rls.tenant_id = '#{tenant_uuid}'")
              end

              teardown do
                connection.send(:execute_sql!, "RESET rls.tenant_id")
              end

              behaves_like_absence_of_rls_table_with_tenant_id(:test_table)
            end

            class WhenRlsNotSet < self
              include RlsTableBehavior

              behaves_like_absence_of_rls_table_without_tenant_id(:test_table)
            end
          end

          class RlsIndexMethodsTest < self
            setup do
              connection.create_rls_tenant_table(:test_table) do |t|
                t.string :name
                t.integer :age
              end
            end

            teardown do
              connection.drop_rls_tenant_table(:test_table, if_exists: true)
            end

            test "create_rls_index adds tenant_id if not present" do
              connection.create_rls_index(:test_table, :name)
              assert connection.index_exists?(:test_table, %i[name tenant_id])
            end

            test "create_rls_index does not duplicate tenant_id if already present" do
              connection.create_rls_index(:test_table, %i[name tenant_id])
              assert connection.index_exists?(:test_table, %i[name tenant_id])
            end

            test "drop_rls_index removes the index with tenant_id" do
              connection.create_rls_index(:test_table, :age)
              assert connection.index_exists?(:test_table, %i[age tenant_id])
              connection.drop_rls_index(:test_table, :age)
              assert_not connection.index_exists?(:test_table, %i[age tenant_id])
            end
          end
        end
      end
    end
  end
end
