# frozen_string_literal: true

require_relative 'down_statements'
require_relative 'up_statements'

module PgRls
  module Schema
    # Schema Statements
    module Statements
      include UpStatements
      include DownStatements

      def create_rls_tenant_table(table_name, **options, &block)
        create_rls_user(password: PgRls.database_configuration['password'])
        create_rls_setter_function
        create_rls_blocking_function
        create_table(table_name, **options, &block)
        add_rls_column_to_tenant_table(table_name)
        append_blocking_function(table_name)
      end

      def create_rls_table(table_name, **options, &block)
        create_table(table_name, **options, &block)
        add_rls_column(table_name)
        create_rls_policy(table_name)
        append_trigger_function(table_name)
      end

      def drop_rls_tenant_table(table_name)
        drop_rls_setter_function
        detach_blocking_function(table_name)
        drop_table(table_name)
        drop_rls_blocking_function
        drop_rls_user
      end

      def drop_rls_table(table_name)
        detach_trigger_function(table_name)
        drop_rls_policy(table_name)
        drop_table(table_name)
      end

      def convert_to_rls_tenant_table(table_name, **_options)
        create_rls_user(password: PgRls.database_configuration['password'])
        create_rls_setter_function
        create_rls_blocking_function
        add_rls_column_to_tenant_table(table_name)
        append_blocking_function(table_name)
      end

      def revert_rls_tenant_table(table_name)
        drop_rls_setter_function
        detach_blocking_function(table_name)
        drop_rls_blocking_function
        drop_rls_user
        drop_rls_column(table_name)
      end

      def convert_to_rls_table(table_name)
        add_rls_column(table_name)
        create_rls_policy(table_name)
        append_trigger_function(table_name)
      end

      def revert_rls_table(table_name)
        detach_trigger_function(table_name)
        drop_rls_policy(table_name)
        drop_rls_column(table_name)
      end
    end
  end
end
