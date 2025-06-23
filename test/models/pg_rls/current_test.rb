# frozen_string_literal: true

require "test_helper"

module PgRls
  class CurrentTest < ::ActiveSupport::TestCase
    test "Current has a tenant attribute" do
      assert Current.defaults.key?(:tenant), "Current should have a tenant attribute"
    end

    test "Current attribute includes post attribute when added" do
      PgRls.setup do |config|
        config.current_attributes = %i[post]
      end

      PgRls.send(:remove_const, "Current") if Object.const_defined?("PgRls::Current")
      load "app/models/pg_rls/current.rb"

      assert Current.defaults.key?(:post), "Current should have a post attribute"
    end

    test "Current fetches the tenant attribute" do
      PgRls.setup do |config|
        config.class_name = :Tenant
        config.table_name = :tenants
        config.search_methods = %i[subdomain tenant]
        config.current_attributes = %i[post]
      end

      PgRls.send(:remove_const, "Current") if Object.const_defined?("PgRls::Current")
      load "app/models/pg_rls/current.rb"

      tenant = ::Tenant.first || ::Tenant.create(name: :test)

      PgRls::Tenant.run_within(tenant) do
        assert_equal tenant.tenant_id, Current.tenant.tenant_id
        post = Current.post
        assert_nil post
      end
    end

    test "Current works with Tenant.run_within" do
      PgRls.setup do |config|
        config.class_name = :Tenant
        config.table_name = :tenants
      end

      tenant = ::Tenant.create!(name: :test)
      result = nil
      PgRls::Tenant.run_within(tenant) do |current_tenant|
        # Compare tenant_id instead of the whole object due to class differences
        assert_equal tenant.tenant_id, current_tenant.tenant_id
        assert_equal tenant.tenant_id, Current.tenant.tenant_id
        result = "success"
      end

      assert_equal "success", result
      assert_nil Current.instance_variable_get(:@attributes)
    end

    test "Current works with Tenant.run_within and two blocks" do
      PgRls.setup do |config|
        config.class_name = :Tenant
        config.table_name = :tenants
      end

      tenant = ::Tenant.create!(name: :test)
      tenant2 = ::Tenant.create!(name: :test2)
      result = nil
      PgRls::Tenant.run_within(tenant) do |current_tenant|
        PgRls::Tenant.run_within(tenant2) do |current_tenant2|
          # Compare tenant2_id instead of the whole object due to class differences
          assert_equal tenant2.tenant_id, current_tenant2.tenant_id
          assert_equal tenant2.tenant_id, Current.tenant.tenant_id
        end
        # Compare tenant_id instead of the whole object due to class differences
        assert_equal tenant.tenant_id, current_tenant.tenant_id
        assert_equal tenant.tenant_id, Current.tenant.tenant_id
        result = "success"
      end

      assert_equal "success", result
      assert_nil Current.instance_variable_get(:@attributes)
    end

    test "Current works with Tenant.switch" do
      PgRls.setup do |config|
        config.class_name = :Tenant
        config.table_name = :tenants
      end

      tenant = ::Tenant.create!(name: :test)

      begin
        PgRls::Tenant.switch(tenant)
        # Verify that Current.tenant is not nil
        assert_not_nil Current.tenant
        # Compare tenant_id instead of the whole object due to class differences
        assert_equal tenant.tenant_id, Current.tenant.tenant_id
      ensure
        PgRls::Tenant.reset_rls
      end
    end
  end
end
