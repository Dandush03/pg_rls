# frozen_string_literal: true

module PgRls
  module ActiveRecord
    module ConnectionAdapters
      module PostgreSQL
        module RlsTableBehavior # rubocop:disable Metrics/ModuleLength
          # rubocop:disable Metrics/MethodLength
          # rubocop:disable Metrics/AbcSize
          # rubocop:disable Metrics/CyclomaticComplexity
          # rubocop:disable Metrics/PerceivedComplexity
          def self.included(base)
            base.define_singleton_method(:behaves_like_rls_table) do |table_name|
              test "ensure that a rls tenant table exists" do
                assert connection.table_exists?(table_name)
              end

              test "ensure users and users privileges exists" do
                assert connection.check_rls_user_privileges!("app_user", "public")
              end

              test "ensure tenant_id_setter function exists" do
                assert connection.function_exists?("tenant_id_setter")
              end

              test "ensure rls_exception function exists" do
                assert connection.function_exists?("rls_exception")
              end

              test "ensure tenant_id_update_blocker function exists" do
                assert connection.function_exists?("tenant_id_update_blocker")
              end

              test "ensure tenant_id column exists" do
                assert_includes connection.columns(table_name).map(&:name), "tenant_id"
              end

              test "ensure rls table has enabled rls" do
                assert connection.check_table_rls_enabled!(table_name)
              end

              test "ensure tenant_id_setter trigger is appended to table" do
                assert connection.trigger_exists?(table_name, "tenant_id_setter")
              end
            end

            base.define_singleton_method(:rls_table_behavior_with_tenant_id) do |table_name|
              test "ensure that the rls tenant_id is set in row after insert" do
                connection.send(:execute_sql!, "INSERT INTO #{table_name} (name) VALUES ('test')")

                record_uuid = connection.send(:execute_sql!,
                                              "SELECT tenant_id FROM #{table_name} WHERE name = 'test'")
                                        .first["tenant_id"]
                assert_equal record_uuid,
                             connection.send(:execute_sql!,
                                             "SELECT current_setting('rls.tenant_id')").first["current_setting"]
              end

              test "raises an InvalidStatement error if tenant_id is manualy updated" do
                uuid = SecureRandom.uuid
                connection.send(:execute_sql!, "INSERT INTO #{table_name} (name) VALUES ('test')")

                assert_raises(::ActiveRecord::StatementInvalid) do
                  connection.send(:execute_sql!, "UPDATE #{table_name} SET tenant_id = '#{uuid}' WHERE name = 'test'")
                end
              end
            end

            base.define_singleton_method(:rls_table_behavior_without_tenant_id) do |table_name|
              test "ensure that the rls tenant_id raise errors" do
                if connection.table_exists?(table_name)
                  assert_raises(::ActiveRecord::StatementInvalid) do
                    connection.send(:execute_sql!, "INSERT INTO #{table_name} (name) VALUES ('test')")
                  end
                else
                  assert true
                end
              end

              test "find all records as admin" do
                if connection.table_exists?(table_name)
                  connection.send(:execute_sql!, "SET rls.tenant_id = '#{SecureRandom.uuid}'")
                  connection.send(:execute_sql!, "INSERT INTO #{table_name} (name) VALUES ('test')")
                  connection.send(:execute_sql!, "INSERT INTO #{table_name} (name) VALUES ('test')")
                  connection.send(:execute_sql!, "RESET rls.tenant_id")

                  assert_equal 2, connection.send(:execute_sql!, "SELECT * FROM #{table_name}").to_a.size
                else
                  assert true
                end
              end
            end

            base.define_singleton_method(:behaves_like_absence_of_rls_table) do |table_name|
              test "ensure tenant_id column does not exists if table exists" do
                if connection.table_exists?(table_name)
                  refute_includes connection.columns(table_name).map(&:name), "tenant_id"
                else
                  assert true
                end
              end

              test "ensure rls table does not has enabled rls" do
                assert_raises(PgRls::ActiveRecord::ConnectionAdapters::PostgreSQL::TableRlsNotEnabledError) do
                  connection.check_table_rls_enabled!(table_name)
                end
              end

              test "ensure tenant_id_setter trigger is not appended to table" do
                refute connection.trigger_exists?(table_name, "tenant_id_setter")
              end

              test "ensure tenant_id_update_blocker trigger not is appended to table" do
                refute connection.trigger_exists?(table_name, "tenant_id_update_blocker")
              end
            end

            base.define_singleton_method(:behaves_like_absence_of_rls_table_with_tenant_id) do |table_name|
              test "ensure that the rls tenant_id does not raise any errors" do
                if connection.table_exists?(table_name)
                  assert_nothing_raised do
                    connection.send(:execute_sql!, "INSERT INTO #{table_name} (name) VALUES ('test')")
                  end
                else
                  assert true
                end
              end

              test "find all records" do
                if connection.table_exists?(table_name)
                  connection.send(:execute_sql!, "INSERT INTO #{table_name} (name) VALUES ('test')")
                  connection.send(:execute_sql!, "SET rls.tenant_id = '#{SecureRandom.uuid}'")
                  connection.send(:execute_sql!, "INSERT INTO #{table_name} (name) VALUES ('test')")
                  connection.send(:execute_sql!, "RESET rls.tenant_id")

                  assert_equal 2, connection.send(:execute_sql!, "SELECT * FROM #{table_name}").to_a.size
                else
                  assert true
                end
              end
            end

            base.define_singleton_method(:behaves_like_absence_of_rls_table_without_tenant_id) do |table_name|
              test "does not raises an error if the tenant_id is not set" do
                if connection.table_exists?(table_name)
                  assert_nothing_raised do
                    connection.send(:execute_sql!, "INSERT INTO #{table_name} (name) VALUES ('test')")
                  end
                else
                  assert true
                end
              end

              test "find all records" do
                if connection.table_exists?(table_name)
                  connection.send(:execute_sql!, "SET rls.tenant_id = '#{SecureRandom.uuid}'")
                  connection.send(:execute_sql!, "INSERT INTO #{table_name} (name) VALUES ('test')")
                  connection.send(:execute_sql!, "INSERT INTO #{table_name} (name) VALUES ('test')")
                  connection.send(:execute_sql!, "RESET rls.tenant_id")

                  assert_equal 2, connection.send(:execute_sql!, "SELECT * FROM #{table_name}").to_a.size
                else
                  assert true
                end
              end
            end
          end
          # rubocop:enable Metrics/MethodLength
          # rubocop:enable Metrics/AbcSize
          # rubocop:enable Metrics/CyclomaticComplexity
          # rubocop:enable Metrics/PerceivedComplexity
        end
      end
    end
  end
end
