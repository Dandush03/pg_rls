# frozen_string_literal: true

require_relative '../statements'
require_relative './up_statements'

module PgRls
  module Schema
    module Solo
      # Schema Solo Statements
      module Statements
        include PgRls::Schema::Statements
        include PgRls::Schema::Solo::UpStatements

        def create_rls_table(table_name, **options, &)
          setup_rls_tenant_table
          create_table(table_name, **options, &)
          add_rls_column(table_name)
          create_rls_policy(table_name)
          append_trigger_function(table_name)
        end
      end
    end
  end
end
