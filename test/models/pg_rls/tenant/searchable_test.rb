# frozen_string_literal: true

require "test_helper"

module PgRls
  class Tenant
    class SearchableTest < ::ActiveSupport::TestCase
      fixtures :tenants

      test "by_rls_object with Tenant input" do
        tenant = tenants(:one)
        pg_tenant = PgRls::Tenant.find(tenant.id)
        assert_equal pg_tenant, Searchable.by_rls_object(pg_tenant)
      end

      test "by_rls_object with String input" do
        tenant = tenants(:one)
        assert_equal PgRls::Tenant.find(tenant.id), Searchable.by_rls_object(tenant.subdomain)
      end

      test "by_rls_object with Symbol input" do
        tenant = tenants(:one)
        assert_equal PgRls::Tenant.find(tenant.id), Searchable.by_rls_object(tenant.subdomain.to_sym)
      end

      test "by_rls_object with Integer input" do
        tenant = tenants(:one)
        assert_equal PgRls::Tenant.find(tenant.id), Searchable.by_rls_object(tenant.id)
      end

      test "by_rls_object with Integer input as string" do
        tenant = tenants(:one)
        assert_equal PgRls::Tenant.find(tenant.id), Searchable.by_rls_object(tenant.id.to_s)
      end

      test "by_rls_object with PgRls::Tenant input" do
        tenant = PgRls::Tenant.find(tenants(:one).id)
        assert_equal tenant, Searchable.by_rls_object(tenant)
      end

      test "by_rls_object with UUID input" do
        tenant = PgRls::Tenant.find(tenants(:one).id)
        assert_equal PgRls::Tenant.find(tenant.id), Searchable.by_rls_object(tenant.tenant_id)
      end

      test "by_rls_object with invalid input raises error" do
        assert_raises(PgRls::Error::InvalidSearchInput) do
          Searchable.by_rls_object(nil)
        end
      end

      test "search method raises error if hash is passed as input" do
        assert_raises(PgRls::Error::InvalidSearchInput) do
          Searchable.new({}).search_methods
        end
      end

      test "search_methods returns integer when input is numeric string" do
        assert_equal ["id"], Searchable.new("123").search_methods
      end

      test "search_methods returns uuid columns when input is UUID format" do
        columns = Searchable.new("550e8400-e29b-41d4-a716-446655440000").search_methods
        assert_includes columns, "tenant_id"
        assert_equal 1, columns.size
      end

      test "by_rls_methods finds tenant by method" do
        # Stub a method that returns a tenant for testing
        Tenant.stub :find_by, Tenant.new do
          tenant = Searchable.by_rls_methods("one-subdomain")
          assert tenant.is_a?(Tenant)
        end
      end

      test "by_rls_methods raises TenantNotFound if no tenant found" do
        Tenant.stub :find_by, nil do
          assert_raises(PgRls::Error::TenantNotFound) do
            Searchable.by_rls_methods("not_found_input")
          end
        end
      end
    end
  end
end
