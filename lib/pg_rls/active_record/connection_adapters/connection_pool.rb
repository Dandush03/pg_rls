# frozen_string_literal: true

module PgRls
  module ActiveRecord
    module ConnectionAdapters
      # ActiveRecord ConnectionPool Connection Adapter Extension
      module ConnectionPool
        def checkout(checkout_timeout = @checkout_timeout)
          conn = super
          return conn unless rls_connection?
          return reset_rls_used_connections(conn) if PgRls::Current.tenant.nil?

          PgRls::Current.tenant.set_rls(conn)
          conn
        end

        def rls_connection?
          pool_config.db_config.configuration_hash[:rls] == true
        end

        def reset_rls_used_connections(connection)
          PgRls::Tenant.reset_rls_used_connections(connection)
        end
      end
    end
  end
end

ActiveRecord::ConnectionAdapters::ConnectionPool.prepend(
  PgRls::ActiveRecord::ConnectionAdapters::ConnectionPool
)
