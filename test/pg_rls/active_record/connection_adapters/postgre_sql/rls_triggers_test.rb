# frozen_string_literal: true

require "test_helper"

module PgRls
  module ActiveRecord
    module ConnectionAdapters
      module PostgreSQL
        class RlsTriggersTest < ::ActiveSupport::TestCase
          attr_reader :connection

          setup do
            @connection = ::ActiveRecord::Base.connection

            connection.create_rls_functions
            connection.create_table("table_name") { |t| t.integer :tenant_id }
          end

          teardown do
            connection.drop_rls_functions
            connection.drop_table("table_name")
          end

          class AppendTenantTableTriggersTest < self
            test "creates the rls_exception trigger" do
              connection.append_tenant_table_triggers("table_name")

              assert connection.trigger_exists?("table_name", "rls_exception")
            end
          end

          class AppendRlsTableTriggersTest < self
            test "creates the tenant_id_setter trigger" do
              connection.append_rls_table_triggers("table_name")

              assert connection.trigger_exists?("table_name", "tenant_id_setter")
            end

            test "creates the tenant_id_update_blocker trigger" do
              connection.append_rls_table_triggers("table_name")

              assert connection.trigger_exists?("table_name", "tenant_id_update_blocker")
            end
          end

          class DropTenantTableTriggersTest < self
            test "drops the rls_exception trigger" do
              connection.append_tenant_table_triggers("table_name")
              connection.drop_tenant_table_triggers("table_name")

              refute connection.trigger_exists?("table_name", "rls_exception")
            end
          end

          class DropRlsTableTriggersTest < self
            test "drops the tenant_id_setter trigger" do
              connection.append_rls_table_triggers("table_name")
              connection.drop_rls_table_triggers("table_name")

              refute connection.trigger_exists?("table_name", "tenant_id_setter")
            end

            test "drops the tenant_id_update_blocker trigger" do
              connection.append_rls_table_triggers("table_name")
              connection.drop_rls_table_triggers("table_name")

              refute connection.trigger_exists?("table_name", "tenant_id_update_blocker")
            end
          end
        end
      end
    end
  end
end
