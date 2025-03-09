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

      def set_rls
        PgRls::Record.connection.exec_query("SET rls.tenant_id = '#{tenant_id}'", prepare: true)

        self
      end

      def reset_rls
        PgRls::Record.connection.exec_query("RESET rls.tenant_id", prepare: true)
        PgRls::Current.reset

        nil
      end

      def readonly?
        true
      end
    end
  end
end
