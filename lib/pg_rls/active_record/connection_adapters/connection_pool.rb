# frozen_string_literal: true

module PgRls
  module ActiveRecord
    module ConnectionAdapters
      # ActiveRecord ConnectionPool Connection Adapter Extension
      module ConnectionPool
        def checkin(conn)
          return unless rls_connection?

          conn.exec_query("SET rls.tenant_id TO DEFAULT", prepare: true)
        ensure
          super
        end

        def checkout(checkout_timeout = @checkout_timeout)
          conn = super
          return conn unless rls_connection?

          PgRls::Current.tenant&.set_rls(conn)

          conn
        end

        def rls_connection?
          pool_config.db_config.configuration_hash[:rls] == true
        end
      end
    end
  end
end

ActiveRecord::ConnectionAdapters::ConnectionPool.prepend(
  PgRls::ActiveRecord::ConnectionAdapters::ConnectionPool
)
