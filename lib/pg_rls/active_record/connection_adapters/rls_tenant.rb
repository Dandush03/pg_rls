# frozen_string_literal: true

module PgRls
  module ActiveRecord
    module ConnectionAdapters
      # Which tenant a connection's session is set to.
      #
      # It belongs to the connection rather than to the thread that set it: a pooled connection moves between
      # threads, and a thread going by its own record of what it once set would skip a connection another thread
      # has since switched to another tenant — and run as that tenant.
      module RlsTenant
        # What the connection's tenant is after a rollback: nobody knows. Postgres undoes a SET made inside a
        # transaction or savepoint that rolls back, so the session is back on whatever tenant it had before —
        # which may be another tenant than the one recorded here. It equals no tenant, so the next switch sets
        # the session again, and it is not nil, so a reset resets it.
        UNKNOWN = Object.new.freeze

        attr_accessor :rls_tenant_id

        # A COMMIT rolls back instead when the transaction has already failed; whether it has is the client library's
        # answer, with no round trip. (A COMMIT that fails is rolled back by Rails, which the hook below hears.)
        def commit_db_transaction
          rolls_back = aborted_transaction?
          super
        ensure
          self.rls_tenant_id = UNKNOWN if rolls_back
        end

        private

        # A new session has no tenant, whatever the connection's last one had: this runs on every connect,
        # reconnect and reset (DISCARD ALL).
        def configure_connection
          super
          self.rls_tenant_id = nil
        end

        def exec_rollback_db_transaction
          super
        ensure
          self.rls_tenant_id = UNKNOWN
        end

        # ROLLBACK AND CHAIN: a nested transaction rolled back in one that had not written yet.
        def exec_restart_db_transaction
          super
        ensure
          self.rls_tenant_id = UNKNOWN
        end

        def exec_rollback_to_savepoint(name = nil)
          super
        ensure
          self.rls_tenant_id = UNKNOWN
        end

        # A connection the client library cannot ask is left to the COMMIT, which raises the real error.
        def aborted_transaction?
          @raw_connection&.transaction_status == ::PG::PQTRANS_INERROR
        rescue ::PG::Error
          false
        end
      end
    end
  end
end

ActiveRecord::ConnectionAdapters::PostgreSQLAdapter.prepend(PgRls::ActiveRecord::ConnectionAdapters::RlsTenant)
