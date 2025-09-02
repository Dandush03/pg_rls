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

      test "reset_rls_used_connections handles nil connection gracefully" do
        # Set up cache to trigger the code path where connection would be used
        PgRls::Tenant.rls_connection_object_cache_by_thread = Set.new(["test"])
        
        # This test reproduces the issue where PgRls::Record.connection returns nil
        PgRls::Record.stub :connection, nil do
          # This should not raise a NoMethodError and should clear the cache
          result = PgRls::Tenant.reset_rls_used_connections
          assert_nil result
          assert_nil PgRls::Tenant.rls_connection_object_cache_by_thread
        end
      end

      test "set_rls handles nil connection gracefully" do
        PgRls::Record.stub :connection, nil do
          # This should not raise a NoMethodError
          result = @tenant.set_rls
          assert_equal @tenant, result
        end
      end
    end
  end
end
