# frozen_string_literal: true

require "test_helper"

module PgRls
  class Tenant
    class SecurableTest < ::ActiveSupport::TestCase
      fixtures :tenants
      def setup
        @tenant = PgRls::Tenant.new
        PgRls::Current.tenant = @tenant
      end

      test "set_rls sets tenant_id in connection" do
        PgRls::Record.connection.stub :execute, true do
          assert_equal @tenant, @tenant.set_rls
        end
      end

      test "reset_rls resets tenant_id in connection" do
        PgRls::Record.connection.stub :execute, true do
          attributes = { tenant: nil, tenant_history: [] }
          assert_equal(PgRls::Tenant.reset_rls, attributes)
          assert_equal(PgRls::Current.attributes, attributes)
          assert_nil PgRls::Current.tenant
        end
      end

      test "readonly? is true" do
        assert @tenant.readonly?
      end

      test "set_rls sets a connection back after another thread left another tenant on it" do
        connection = PgRls::Record.connection
        one, two = tenants_named(:one, :two)

        one.set_rls(connection)
        # Pooled connections move between threads: a request on another one takes it and switches it.
        Thread.new { two.set_rls(connection) }.join
        one.set_rls(connection)

        assert_equal one.tenant_id, session_tenant(connection)
      end

      test "set_rls does not set a connection again that is already on that tenant" do
        connection = PgRls::Record.connection
        one, = tenants_named(:one)
        one.set_rls(connection)

        assert_empty(statements_setting_the_tenant { one.set_rls(connection) })
        assert_equal one.tenant_id, session_tenant(connection)
      end

      test "set_rls sets a connection again once a reconnect has dropped its session" do
        connection = PgRls::Record.connection
        one, = tenants_named(:one)
        one.set_rls(connection)

        connection.reconnect!
        one.set_rls(connection)

        assert_equal one.tenant_id, session_tenant(connection)
      end

      test "reset_rls_used_connections takes a connection's tenant off it" do
        connection = PgRls::Record.connection
        one, = tenants_named(:one)
        one.set_rls(connection)

        PgRls::Tenant.reset_rls_used_connections(connection)

        assert_empty session_tenant(connection).to_s
        # And from another thread too: what matters is the connection's tenant, not who set it.
        one.set_rls(connection)
        Thread.new { PgRls::Tenant.reset_rls_used_connections(connection) }.join

        assert_empty session_tenant(connection).to_s
      end

      test "reset_rls_used_connections leaves a connection with no tenant alone" do
        connection = PgRls::Record.connection
        PgRls::Tenant.reset_rls_used_connections(connection)

        assert_empty(statements_setting_the_tenant { PgRls::Tenant.reset_rls_used_connections(connection) })
      end

      private

      def tenants_named(*names)
        names.map { |name| PgRls::Tenant.find_by!(tenant_id: tenants(name).tenant_id) }
      end

      def session_tenant(connection)
        connection.select_value("SELECT current_setting('rls.tenant_id', true)")
      end

      def statements_setting_the_tenant(&block)
        statements = []
        callback = ->(*, payload) { statements << payload[:sql] if payload[:sql].include?("rls.tenant_id") }
        ::ActiveSupport::Notifications.subscribed(callback, "sql.active_record", &block)
        statements
      end
    end
  end
end
