# frozen_string_literal: true

module PgRls
  module ActiveRecord
    module ConnectionAdapters
      module PostgreSQL
        module RlsTenantTableBehavior
          def self.included(base)
            base.define_singleton_method(:behaves_like_rls_tenant_table) do |table_name|
              test "ensure that a rls tenant table exists" do
                assert connection.table_exists?(table_name)
              end

              test "creates rls_group and user with default privileges" do
                assert connection.check_rls_user_privileges!("test_app_user", "public")
              end

              test "creates tenant_id_setter function" do
                assert connection.function_exists?("tenant_id_setter")
              end

              test "creates rls_exception function" do
                assert connection.function_exists?("rls_exception")
              end

              test "creates tenant_id_update_blocker function" do
                assert connection.function_exists?("tenant_id_update_blocker")
              end

              test "appends rls column tenant_id" do
                assert_includes connection.columns(table_name).map(&:name), "tenant_id"
              end

              test "ensures tenant_id column is indexed" do
                assert_includes connection.indexes(table_name).map(&:name), "index_#{table_name}_on_tenant_id"
              end

              test "appends tenant table triggers (tenant_id_setter)" do
                assert connection.trigger_exists?(table_name, "rls_exception")
              end

              test "raises an InvalidStatement error if the row tenant_id is edited" do
                connection.send(:execute_sql!, "INSERT INTO #{table_name} (name) VALUES ('test')")

                assert_raises(::ActiveRecord::StatementInvalid) do
                  connection.send(:execute_sql!, "UPDATE #{table_name} SET tenant_id = 'test' WHERE name = 'test'")
                end
              end
            end

            base.define_singleton_method(:behaves_like_absence_of_rls_tenant_table) do |table_name|
              test "rls_group and user with default privileges does not exists" do
                assert_raises(PgRls::Error) do
                  connection.check_rls_user_privileges!("test_app_user", "public")
                end
              end

              test "tenant_id_setter function does not exists" do
                refute connection.function_exists?("tenant_id_setter")
              end

              test "rls_exception function does not exists" do
                refute connection.function_exists?("rls_exception")
              end

              test "tenant_id_update_blocker function does not exists" do
                refute connection.function_exists?("tenant_id_update_blocker")
              end

              test "tenant table triggers (tenant_id_setter) does not exists" do
                refute connection.trigger_exists?(table_name, "rls_exception")
              end
            end
          end
        end
      end
    end
  end
end
