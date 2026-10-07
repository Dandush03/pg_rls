# frozen_string_literal: true

require "test_helper"

module PgRls
  module ActiveRecord
    module ConnectionAdapters
      # Postgres takes a `SET` back when the transaction it ran in rolls back, or the savepoint it ran after: the
      # session goes back to the tenant it had before. The connection must not go on believing it is on the tenant it
      # set, or the next `set_rls` to that tenant is skipped and its queries run as the one before.
      #
      # Each test has a connection of its own, out of the pool and out of the test's transaction, so that its
      # transactions are real ones: BEGIN, COMMIT and ROLLBACK, as an app's are.
      class RlsTenantTest < ::ActiveSupport::TestCase # rubocop:disable Metrics/ClassLength
        fixtures :tenants

        setup do
          @connection = PgRls::Record.connection_pool.db_config.new_connection
          @one, @two = %i[one two].map { |name| PgRls::Tenant.find_by!(tenant_id: tenants(name).tenant_id) }
        end

        teardown do
          @connection&.disconnect!
        end

        test "a rolled back transaction takes its tenant back, and the connection sets it again" do
          @one.set_rls(@connection)
          @connection.transaction do
            @two.set_rls(@connection)
            raise ::ActiveRecord::Rollback
          end
          assert_equal @one.tenant_id, session_tenant, "Postgres put the session back on the tenant before"

          @two.set_rls(@connection)

          assert_equal @two.tenant_id, session_tenant
        end

        test "a query after a rolled back transaction never sees the tenant before's rows" do
          @one.set_rls(@connection)
          write_post_of_the_session_tenant
          @connection.transaction do
            @two.set_rls(@connection)
            raise ::ActiveRecord::Rollback
          end

          @two.set_rls(@connection)

          assert_equal 0, @connection.select_value("SELECT count(*) FROM posts"), "the post is tenant one's"
        ensure
          @connection.execute("SET rls.tenant_id = '#{@one.tenant_id}'")
          @connection.execute("DELETE FROM posts")
        end

        test "a rolled back transaction on a connection with no tenant before leaves it with none, and sets it again" do
          @connection.transaction do
            @one.set_rls(@connection)
            raise ::ActiveRecord::Rollback
          end
          assert_empty session_tenant.to_s

          @one.set_rls(@connection)

          assert_equal @one.tenant_id, session_tenant
        end

        test "a transaction rolled back by an exception takes its tenant back" do
          @one.set_rls(@connection)
          assert_raises(ArgumentError) do
            @connection.transaction do
              @two.set_rls(@connection)
              raise ArgumentError
            end
          end

          @two.set_rls(@connection)

          assert_equal @two.tenant_id, session_tenant
        end

        test "a joined nested transaction that raises rolls the whole transaction back, and its tenant with it" do
          @one.set_rls(@connection)
          assert_raises(ArgumentError) do
            @connection.transaction do
              @connection.transaction do
                @two.set_rls(@connection)
                raise ArgumentError
              end
            end
          end

          @two.set_rls(@connection)

          assert_equal @two.tenant_id, session_tenant
        end

        test "a rolled back savepoint takes back the tenant set after it" do
          statements = statements_run do
            @connection.transaction do
              @one.set_rls(@connection)
              write_something # a transaction that has written can only go back to a savepoint
              @connection.transaction(requires_new: true) do
                @two.set_rls(@connection)
                raise ::ActiveRecord::Rollback
              end
              assert_equal @one.tenant_id, session_tenant, "Postgres put the session back on the tenant before"

              @two.set_rls(@connection)

              assert_equal @two.tenant_id, session_tenant
            end
          end

          assert(statements.any? { |sql| sql.start_with?("ROLLBACK TO SAVEPOINT") })
        end

        test "a requires_new transaction in one that has not written restarts it, and takes its tenant back" do
          statements = statements_run do
            @one.set_rls(@connection)
            @connection.transaction do
              @connection.transaction(requires_new: true) do
                @two.set_rls(@connection)
                raise ::ActiveRecord::Rollback
              end
              assert_equal @one.tenant_id, session_tenant, "Postgres put the session back on the tenant before"

              @two.set_rls(@connection)

              assert_equal @two.tenant_id, session_tenant
            end
          end

          assert_includes statements, "ROLLBACK AND CHAIN"
        end

        test "a commit of a failed transaction rolls it back, and takes its tenant back" do
          @one.set_rls(@connection)
          statements = statements_run do
            @connection.transaction do
              @two.set_rls(@connection)
              assert_raises(::ActiveRecord::StatementInvalid) { @connection.select_value("SELECT 1 / 0") }
            end
          end
          assert_includes statements, "COMMIT"
          assert_equal @one.tenant_id, session_tenant, "Postgres rolled the transaction back"

          @two.set_rls(@connection)

          assert_equal @two.tenant_id, session_tenant
        end

        test "a commit that fails rolls the transaction back, and takes its tenant back" do
          @connection.execute("CREATE TEMPORARY TABLE deferred (id integer UNIQUE DEFERRABLE INITIALLY DEFERRED)")
          @one.set_rls(@connection)
          assert_raises(::ActiveRecord::RecordNotUnique) do
            @connection.transaction do
              @two.set_rls(@connection)
              @connection.execute("INSERT INTO deferred VALUES (1), (1)")
            end
          end

          @two.set_rls(@connection)

          assert_equal @two.tenant_id, session_tenant
        end

        test "a ROLLBACK that raises still leaves the connection not knowing its tenant" do
          @one.set_rls(@connection)
          # Rails swallows a lost connection on rollback (rollback_db_transaction): the ROLLBACK may never have run.
          fail_on("ROLLBACK", ::ActiveRecord::ConnectionFailed)
          @connection.transaction do
            @two.set_rls(@connection)
            raise ::ActiveRecord::Rollback
          end

          assert_equal RlsTenant::UNKNOWN, @connection.rls_tenant_id
          assert_not_empty(statements_setting_the_tenant { @two.set_rls(@connection) })
        end

        test "a connection the client library cannot ask whether its transaction failed is left to COMMIT" do
          @connection.transaction do
            @one.set_rls(@connection)
            def (@connection.instance_variable_get(:@raw_connection)).transaction_status
              raise ::PG::ConnectionBad
            end
          end

          assert_equal @one.tenant_id, @connection.rls_tenant_id, "the COMMIT went through"
        end

        test "a committed transaction keeps its tenant, and the connection does not set it again" do
          @connection.transaction do
            @connection.transaction(requires_new: true) { @one.set_rls(@connection) }
          end

          assert_empty(statements_setting_the_tenant { @one.set_rls(@connection) })
          assert_equal @one.tenant_id, session_tenant
        end

        test "reset_rls_used_connections takes the tenant off a connection that no longer knows its tenant" do
          @one.set_rls(@connection)
          @connection.transaction do
            @two.set_rls(@connection)
            raise ::ActiveRecord::Rollback
          end
          assert_equal RlsTenant::UNKNOWN, @connection.rls_tenant_id

          PgRls::Tenant.reset_rls_used_connections(@connection)

          assert_empty session_tenant.to_s
          assert_nil @connection.rls_tenant_id
        end

        test "a connection that no longer knows its tenant learns it again on reconnect" do
          @connection.transaction do
            @one.set_rls(@connection)
            raise ::ActiveRecord::Rollback
          end

          @connection.reconnect!

          assert_nil @connection.rls_tenant_id
        end

        private

        def session_tenant
          @connection.select_value("SELECT current_setting('rls.tenant_id', true)")
        end

        # Committed, so that it outlives the transactions of the test: posts take the session's tenant (a trigger).
        def write_post_of_the_session_tenant
          @connection.execute("INSERT INTO posts (title, created_at, updated_at) VALUES ('one''s', now(), now())")
          assert_equal 1, @connection.select_value("SELECT count(*) FROM posts")
        end

        def fail_on(statement, error)
          @connection.define_singleton_method(:internal_execute) do |sql, *args, **options|
            raise error if sql == statement

            super(sql, *args, **options)
          end
        end

        def write_something
          @connection.update("UPDATE tenants SET name = name WHERE false")
        end

        def statements_run(&block)
          statements = []
          callback = ->(*, payload) { statements << payload[:sql] if payload[:connection].equal?(@connection) }
          ::ActiveSupport::Notifications.subscribed(callback, "sql.active_record", &block)
          statements
        end

        def statements_setting_the_tenant(&block)
          statements_run(&block).select { |sql| sql.include?("rls.tenant_id") }
        end
      end
    end
  end
end
