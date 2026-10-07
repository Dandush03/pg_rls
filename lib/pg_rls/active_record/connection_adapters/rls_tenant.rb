# frozen_string_literal: true

module PgRls
  module ActiveRecord
    module ConnectionAdapters
      # Which tenant a connection's session is set to.
      #
      # It belongs to the connection rather than to the thread that set it: a pooled connection moves between
      # threads, and a thread going by its own record of what it once set would skip a connection another thread
      # has since switched to another tenant — and run as that tenant.
      #
      # It is only a record of the last `SET` sent, and Postgres can take that `SET` back on its own: rolling back a
      # transaction, or to a savepoint, puts the session back on the tenant it had before it — whatever the record
      # says. After any of those the connection no longer knows its tenant (UNKNOWN), and the next `Tenant#set_rls`
      # or `Tenant.reset_rls_used_connections` sends its statement whatever the tenant asked for.
      module RlsTenant
        # The session may be on any tenant, or none. Never equal to a tenant id, and not nil either: nil says the
        # session has no tenant, which would let `Tenant.reset_rls_used_connections` leave a tenant on it.
        UNKNOWN = :unknown

        attr_accessor :rls_tenant_id

        # ROLLBACK: the session is back on the tenant it had when the transaction began.
        def exec_rollback_db_transaction
          super
        ensure
          forget_rls_tenant
        end

        # ROLLBACK AND CHAIN: as ROLLBACK, before the next transaction begins.
        def exec_restart_db_transaction
          super
        ensure
          forget_rls_tenant
        end

        # ROLLBACK TO SAVEPOINT: the session is back on the tenant it had when the savepoint was taken.
        def exec_rollback_to_savepoint(...)
          super
        ensure
          forget_rls_tenant
        end

        # COMMIT rolls back instead when the transaction has already failed — and when the commit itself fails, as a
        # deferred constraint can make it — and takes the transaction's `SET` back with it. Asking whether it failed
        # is answered by the client library, without a round trip.
        def commit_db_transaction
          committed = false
          aborted = rls_transaction_aborted?
          result = super
          committed = !aborted
          result
        ensure
          forget_rls_tenant unless committed
        end

        private

        # A new session has no tenant, whatever the connection's last one had: this runs on every connect,
        # reconnect and reset (DISCARD ALL).
        def configure_connection
          super
          self.rls_tenant_id = nil
        end

        def forget_rls_tenant
          self.rls_tenant_id = UNKNOWN
        end

        def rls_transaction_aborted?
          @raw_connection&.transaction_status == ::PG::PQTRANS_INERROR
        end
      end
    end
  end
end

ActiveRecord::ConnectionAdapters::PostgreSQLAdapter.prepend(PgRls::ActiveRecord::ConnectionAdapters::RlsTenant)
