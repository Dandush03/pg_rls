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
          result = PgRls::Tenant.reset_rls

          assert_equal({ post: nil, tenant: nil }, result)
          assert_nil PgRls::Current.tenant
        end
      end

      test "readonly? is true" do
        assert @tenant.readonly?
      end
    end
  end
end
