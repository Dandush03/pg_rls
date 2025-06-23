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
        def reset_rls_used_connections(connection = PgRls::Record.connection)
          return connection if rls_connection_object_cache_by_thread.nil?

          connection.exec_query("SET rls.tenant_id TO DEFAULT")
          self.rls_connection_object_cache_by_thread = nil
          connection
        end

        def rls_connection_object_cache_by_thread=(value)
          ::ActiveSupport::IsolatedExecutionState[:active_record_rls_used_connections] = value
        end

        def rls_connection_object_cache_by_thread
          ::ActiveSupport::IsolatedExecutionState[:active_record_rls_used_connections]
        end
      end

      def set_rls(connection = PgRls::Record.connection)
        self.class.reset_rls_used_connections if new_tenant?
        return self if reused_connection?(connection)

        connection.exec_query("SET rls.tenant_id = '#{tenant_id}'")

        self
      end

      def readonly?
        true
      end

      private

      def new_tenant?
        !rls_used_connections.add?(tenant_id).nil?
      end

      def reused_connection?(conn)
        rls_used_connections.add?(conn.object_id).nil?
      end

      def rls_used_connections
        if self.class.rls_connection_object_cache_by_thread.nil?
          self.class.rls_connection_object_cache_by_thread = Set.new([tenant_id])
        end

        self.class.rls_connection_object_cache_by_thread
      end
    end
  end
end
