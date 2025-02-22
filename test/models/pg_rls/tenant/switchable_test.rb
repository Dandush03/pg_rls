# frozen_string_literal: true

require "test_helper"

module PgRls
  class Tenant
    class SwitchableTest < ::ActiveSupport::TestCase
      fixtures :tenants
      test "switch sets tenant RLS" do
        tenant = Tenant.new
        Tenant::Searchable.stub :by_rls_object, tenant do
          assert_equal tenant, Tenant.switch(tenant)
        end
      end

      test "switch returns nil if tenant not found" do
        assert_nil Tenant.switch("not_found")
      end

      test "switch! raises error if tenant not found" do
        assert_raises(PgRls::Error::TenantNotFound) do
          Tenant.switch!("not_found")
        end
      end

      test "run_within sets RLS for tenant and resets after block" do
        tenant = Tenant.new
        Tenant::Searchable.stub :by_rls_object, tenant do
          tenant.stub :set_rls, true do
            tenant.stub :reset_rls, true do
              result = Tenant.run_within("tenant_input") { "block result" }
              assert_equal "block result", result
            end
          end
        end
      end

      test "with_tenant! executes run_within with deprecation warning" do
        tenant = Tenant.new
        Tenant::Searchable.stub :by_rls_object, tenant do
          tenant.stub :set_rls, true do
            tenant.stub :reset_rls, true do
              # rubocop:disable Layout/LineLength
              output_regex = /DEPRECATION WARNING: This method is deprecated and will be removed in future versions. please use PgRls::Tenant.run_within instead. \(called from with_tenant! at .*switchable.rb:33\)\n/
              # rubocop:enable Layout/LineLength
              assert_output(nil, output_regex) do
                result = Tenant.with_tenant!("tenant_input") { "block result" }
                assert_equal "block result", result
              end
            end
          end
        end
      end
    end
  end
end
