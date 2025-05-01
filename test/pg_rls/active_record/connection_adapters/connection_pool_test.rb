# frozen_string_literal: true

require "test_helper"

module PgRls
  module ActiveRecord
    module ConnectionAdapters
      class ConnectionPoolTest < ::ActiveSupport::TestCase
        def setup
          PgRls.class_name = :Tenant
          PgRls.table_name = :tenants
          PgRls.search_methods = %i[subdomain tenant]
          @tenant = ::Tenant.first || ::Tenant.create(name: :test)
          PgRls::Current.reset
          @pool = ::ActiveRecord::Base.connection_pool
        end

        test "checkout returns conn if not rls_connection" do
          @pool.stub :rls_connection?, false do
            conn = @pool.checkout
            assert conn
          end
        end

        test "checkout sets rls if tenant is present" do
          PgRls::Tenant.switch @tenant
          @pool.stub :rls_connection?, true do
            called = false
            PgRls::Current.tenant.define_singleton_method(:set_rls) { |_conn| called = true }
            conn = @pool.checkout
            assert conn
            assert called
          end
        end

        test "rls_connection? returns a boolean" do
          assert_includes [true, false], @pool.rls_connection?
        end
      end
    end
  end
end
