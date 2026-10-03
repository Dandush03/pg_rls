# frozen_string_literal: true

module PgRls
  class Tenant
    # Securable Module
    module Securable
      extend ::ActiveSupport::Concern

      included do
        self.table_name = PgRls.table_name

        self.ignored_columns = column_names.reject do |column|
          PgRls.search_methods.map(&:to_s).include?(column)
        end
      end

      class_methods do
        # Takes the tenant off a connection, when it has one (PgRls::ActiveRecord::ConnectionAdapters::RlsTenant).
        def reset_rls_used_connections(connection = PgRls::Record.connection)
          return connection if connection.rls_tenant_id.nil?

          connection.exec_query("SET rls.tenant_id TO DEFAULT")
          connection.rls_tenant_id = nil
          connection
        end
      end

      # Sets the connection's session to this tenant, unless it already is: what decides is the tenant the
      # connection itself is on, never which thread set it last.
      def set_rls(connection = PgRls::Record.connection)
        return self if connection.rls_tenant_id == tenant_id

        connection.exec_query("SET rls.tenant_id = '#{tenant_id}'")
        connection.rls_tenant_id = tenant_id

        self
      end

      def readonly?
        true
      end
    end
  end
end
