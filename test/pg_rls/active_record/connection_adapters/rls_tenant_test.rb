# frozen_string_literal: true

require "test_helper"

module PgRls
  module ActiveRecord
    module ConnectionAdapters
      # A connection's tenant after a transaction rolls back, with nothing stubbed and no test transaction around it:
      # the rollback is a real ROLLBACK, and Postgres really undoes the SET made inside it.
      class RlsTenantTest < ::ActiveSupport::TestCase
        self.use_transactional_tests = false
        fixtures :tenants

        def setup
          @connection = PgRls::Record.connection
          @one, @two = %w[one-subdomain two-subdomain].map { |subdomain| PgRls::Tenant.find_by!(subdomain: subdomain) }
        end

        def teardown
          PgRls::Tenant.reset_rls_used_connections(@connection)
        end

        test "a rolled-back transaction leaves the tenant unknown, and the next switch sets the session again" do
          @two.set_rls(@connection)

          @connection.transaction do
            @one.set_rls(@connection)
            raise ::ActiveRecord::Rollback
          end

          assert_same RlsTenant::UNKNOWN, @connection.rls_tenant_id
          assert_equal @two.tenant_id, session_tenant, "Postgres took the session back to the tenant before"

          @one.set_rls(@connection)

          assert_equal @one.tenant_id, session_tenant
        end

        test "a nested transaction rolled back in one that had not written restarts it, and the tenant is unknown" do
          @two.set_rls(@connection)

          statements = sent do
            @connection.transaction do
              @connection.transaction(requires_new: true) do
                @one.set_rls(@connection)
                raise ::ActiveRecord::Rollback
              end
            end
          end

          assert(statements.any? { |sql| sql.match?(/ROLLBACK AND CHAIN/i) }, "Rails restarted the transaction")
          assert_same RlsTenant::UNKNOWN, @connection.rls_tenant_id
          @one.set_rls(@connection)

          assert_equal @one.tenant_id, session_tenant
        end

        test "a COMMIT of a transaction that already failed rolls back, and the tenant is unknown" do
          @two.set_rls(@connection)

          @connection.transaction do
            @one.set_rls(@connection)
            begin
              @connection.execute("SELECT 1/0")
            rescue ::ActiveRecord::StatementInvalid
              nil
            end
          end

          assert_same RlsTenant::UNKNOWN, @connection.rls_tenant_id
          assert_equal @two.tenant_id, session_tenant, "Postgres took the session back to the tenant before"
        end

        test "a COMMIT that fails rolls back, and the tenant is unknown" do
          @connection.execute("CREATE TEMP TABLE twice (id int UNIQUE DEFERRABLE INITIALLY DEFERRED)")

          assert_raises(::ActiveRecord::RecordNotUnique) do
            @connection.transaction do
              @one.set_rls(@connection)
              @connection.execute("INSERT INTO twice VALUES (1), (1)")
            end
          end

          assert_same RlsTenant::UNKNOWN, @connection.rls_tenant_id
          assert_empty session_tenant.to_s
        ensure
          @connection.execute("DROP TABLE IF EXISTS twice")
        end

        test "a COMMIT the client library cannot ask about is left to Postgres, and keeps the tenant it set" do
          raw = @connection.raw_connection
          raw.define_singleton_method(:transaction_status) { raise ::PG::ConnectionBad, "gone" }

          @connection.transaction { @one.set_rls(@connection) }

          assert_equal @one.tenant_id, @connection.rls_tenant_id
        ensure
          raw.singleton_class.remove_method(:transaction_status)
        end

        test "a committed transaction keeps the tenant it set" do
          @connection.transaction { @one.set_rls(@connection) }

          assert_equal @one.tenant_id, @connection.rls_tenant_id
          assert_equal @one.tenant_id, session_tenant
        end

        private

        def sent(&block)
          statements = []
          callback = ->(*, payload) { statements << payload[:sql] }
          ::ActiveSupport::Notifications.subscribed(callback, "sql.active_record", &block)
          statements
        end

        def session_tenant
          @connection.select_value("SELECT current_setting('rls.tenant_id', true)")
        end
      end
    end
  end
end
