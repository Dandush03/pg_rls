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
        attr_accessor :rls_tenant_id

        private

        # A new session has no tenant, whatever the connection's last one had: this runs on every connect,
        # reconnect and reset (DISCARD ALL).
        def configure_connection
          super
          self.rls_tenant_id = nil
        end
      end
    end
  end
end

ActiveRecord::ConnectionAdapters::PostgreSQLAdapter.prepend(PgRls::ActiveRecord::ConnectionAdapters::RlsTenant)
