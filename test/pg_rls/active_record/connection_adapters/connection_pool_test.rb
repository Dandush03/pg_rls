# frozen_string_literal: true

require "test_helper"

module PgRls
  module ActiveRecord
    module ConnectionAdapters
      class ConnectionPoolTest < ::ActiveSupport::TestCase
        fixtures :tenants

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

        # The pool as two requests use it, with nothing stubbed: a real connection, real threads, and the session's
        # own setting read back. Between two queries of one request the connection goes back to the pool - as it does
        # whenever nothing holds it for the whole request - and another request takes it and switches it.
        test "a connection another request switched mid-request is switched back at its next checkout" do
          rls_pool = PgRls::Record.connection_pool
          one, two = %w[one-subdomain two-subdomain].map { |subdomain| PgRls::Tenant.find_by!(subdomain: subdomain) }
          go = Queue.new
          answers = Queue.new

          first = Thread.new do
            start_request(rls_pool, one)
            answers << ask_the_session(rls_pool)
            go.pop
            answers << ask_the_session(rls_pool)
          end
          before = answers.pop
          Thread.new do
            start_request(rls_pool, two)
            answers << ask_the_session(rls_pool)
          end.join
          between = answers.pop
          go << :next_query
          first.join
          after = answers.pop

          assert_equal [before.first] * 3, [before, between, after].map(&:first), "the three asked one connection"
          assert_equal [one.tenant_id, two.tenant_id, one.tenant_id], [before, between, after].map(&:last)
        end

        test "rls_connection? returns a boolean" do
          assert_includes [true, false], @pool.rls_connection?
        end

        private

        # A request begins: no tenant, then its own; nothing held from the pool.
        def start_request(rls_pool, tenant)
          PgRls::Current.reset
          PgRls::Current.tenant = tenant
          rls_pool.release_connection
        end

        # One query: a connection checked out, asked what tenant its session is on, and handed back.
        def ask_the_session(rls_pool)
          rls_pool.with_connection do |connection|
            [connection.object_id, connection.select_value("SELECT current_setting('rls.tenant_id', true)")]
          end
        end
      end
    end
  end
end
