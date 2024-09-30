# frozen_string_literal: true

module PgRls
  module ActiveRecord
    module ConnectionAdapters
      module PostgreSQL
        # This module contains the logic to create, drop and validate RLS functions
        module RlsFunctions
          def function_exists?(function_name)
            query = <<~SQL.sanitize_sql
              SELECT 1
              FROM pg_proc
              WHERE proname = '#{function_name}'
            SQL

            execute(query).any?
          end

          def create_function(name, body)
            query = <<~SQL.sanitize_sql
              CREATE OR REPLACE FUNCTION #{name}()
                RETURNS TRIGGER LANGUAGE plpgsql AS $$
                #{body}
                $$;
            SQL

            execute(query)
          end

          def drop_function(name)
            query = <<~SQL.sanitize_sql
              DROP FUNCTION IF EXISTS #{name}();
            SQL

            execute(query)
          end
        end
      end
    end
  end
end

ActiveRecord::ConnectionAdapters::AbstractAdapter.include(
  PgRls::ActiveRecord::ConnectionAdapters::PostgreSQL::RlsFunctions
)
