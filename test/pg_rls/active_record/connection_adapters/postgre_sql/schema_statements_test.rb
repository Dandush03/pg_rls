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
            @connection = ::ActiveRecord::Base.connection
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
              connection.create_table(:test_table) { |t| t.string :name }
              connection.convert_to_rls_tenant_table(:test_table)
            end

            teardown do
              connection.drop_table(:test_table, if_exists: true)
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
                connection.execute("SET rls.tenant_id = '#{tenant_uuid}'")
              end

              teardown do
                connection.execute("RESET rls.tenant_id")
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
                connection.execute("SET rls.tenant_id = '#{tenant_uuid}'")
              end

              teardown do
                connection.execute("RESET rls.tenant_id")
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
                connection.execute("SET rls.tenant_id = '#{tenant_uuid}'")
              end

              teardown do
                connection.execute("RESET rls.tenant_id")
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
                connection.execute("SET rls.tenant_id = '#{tenant_uuid}'")
              end

              teardown do
                connection.execute("RESET rls.tenant_id")
              end

              behaves_like_absence_of_rls_table_with_tenant_id(:test_table)
            end

            class WhenRlsNotSet < self
              include RlsTableBehavior

              behaves_like_absence_of_rls_table_without_tenant_id(:test_table)
            end
          end
        end
      end
    end
  end
end
