# frozen_string_literal: true

require "test_helper"

module PgRls
  class CurrentTest < ::ActiveSupport::TestCase
    test "Current has a tenant attribute" do
      assert Current.attributes.key?(:tenant), "Current should have a tenant attribute"
    end

    test "Current attribute includes post attribute when added" do
      PgRls.setup do |config|
        config.current_attributes = %i[post]
      end

      PgRls.send(:remove_const, "Current") if Object.const_defined?("PgRls::Current")
      load "app/models/pg_rls/current.rb"

      assert Current.attributes.key?(:post), "Current should have a post attribute"
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
        post = Post.first || Post.create(title: "test")
        assert_equal tenant.tenant_id, Current.tenant.tenant_id

        assert_equal post, Current.post
      end
    end
  end
end
