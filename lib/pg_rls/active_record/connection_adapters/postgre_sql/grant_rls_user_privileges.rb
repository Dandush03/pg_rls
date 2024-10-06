# frozen_string_literal: true

module PgRls
  module ActiveRecord
    module ConnectionAdapters
      module PostgreSQL
        # This module contains the logic to grant user privileges
        module GrantRlsUserPrivileges
          include SqlHelperMethod

          def grant_rls_user_privileges(schema)
            grant_schema_usage("rls_group", schema)
            grant_default_sequence_privileges("rls_group", schema)
            grant_default_table_privileges("rls_group", schema)
            grant_existing_table_privileges("rls_group", schema)
            grant_existing_sequence_privileges("rls_group", schema)
          end

          def revoke_rls_user_privileges(schema)
            revoke_schema_usage("rls_group", schema)
            revoke_default_sequence_privileges("rls_group", schema)
            revoke_default_table_privileges("rls_group", schema)
            revoke_existing_table_privileges("rls_group", schema)
            revoke_existing_sequence_privileges("rls_group", schema)
          end

          private

          def revoke_schema_usage(name, schema)
            statement = <<~SQL
              REVOKE USAGE ON SCHEMA #{schema} FROM #{name};
            SQL
            execute_sql!(statement)
          end

          def revoke_default_sequence_privileges(name, schema)
            statement = <<~SQL
              ALTER DEFAULT PRIVILEGES IN SCHEMA #{schema}
                REVOKE USAGE, SELECT ON SEQUENCES FROM #{name};
            SQL
            execute_sql!(statement)
          end

          def revoke_default_table_privileges(name, schema)
            statement = <<~SQL
              ALTER DEFAULT PRIVILEGES IN SCHEMA #{schema}
                REVOKE SELECT, INSERT, UPDATE, DELETE ON TABLES FROM #{name};
            SQL
            execute_sql!(statement)
          end

          def revoke_existing_table_privileges(name, schema)
            statement = <<~SQL
              REVOKE SELECT, INSERT, UPDATE, DELETE
                ON ALL TABLES IN SCHEMA #{schema} FROM #{name};
            SQL
            execute_sql!(statement)
          end

          def revoke_existing_sequence_privileges(name, schema)
            statement = <<~SQL
              REVOKE USAGE, SELECT
                ON ALL SEQUENCES IN SCHEMA #{schema} FROM #{name};
            SQL
            execute_sql!(statement)
          end

          def grant_schema_usage(name, schema)
            statement = <<~SQL
              GRANT USAGE ON SCHEMA #{schema} TO #{name};
            SQL
            execute_sql!(statement)
          end

          def grant_default_sequence_privileges(name, schema)
            statement = <<~SQL
              ALTER DEFAULT PRIVILEGES IN SCHEMA #{schema}
                GRANT USAGE, SELECT ON SEQUENCES TO #{name};
            SQL
            execute_sql!(statement)
          end

          def grant_default_table_privileges(name, schema)
            statement = <<~SQL
              ALTER DEFAULT PRIVILEGES IN SCHEMA #{schema}
                GRANT SELECT, INSERT, UPDATE, DELETE ON TABLES TO #{name};
            SQL
            execute_sql!(statement)
          end

          def grant_existing_table_privileges(name, schema)
            statement = <<~SQL
              GRANT SELECT, INSERT, UPDATE, DELETE
                ON ALL TABLES IN SCHEMA #{schema} TO #{name};
            SQL
            execute_sql!(statement)
          end

          def grant_existing_sequence_privileges(name, schema)
            statement = <<~SQL
              GRANT USAGE, SELECT
                ON ALL SEQUENCES IN SCHEMA #{schema} TO #{name};
            SQL
            execute_sql!(statement)
          end
        end
      end
    end
  end
end
