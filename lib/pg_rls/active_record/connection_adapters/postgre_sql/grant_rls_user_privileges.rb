# frozen_string_literal: true

module PgRls
  module ActiveRecord
    module ConnectionAdapters
      module PostgreSQL
        # This module contains the logic to grant user privileges
        module GrantRlsUserPrivileges
          include SqlHelperMethod

          def grant_rls_user_privileges(schema = PgRls.schema, role_name = PgRls.rls_role_group)
            grant_schema_usage(schema, role_name)
            grant_schema_migration_table_privileges(schema, role_name)
            grant_default_sequence_privileges(schema, role_name)
            grant_default_table_privileges(schema, role_name)
            grant_existing_table_privileges(schema, role_name)
            grant_existing_sequence_privileges(schema, role_name)
          end

          def revoke_rls_user_privileges(schema = PgRls.schema, role_name = PgRls.rls_role_group)
            revoke_schema_usage(schema, role_name)
            revoke_schema_migration_table_privileges(schema, role_name)
            revoke_default_sequence_privileges(schema, role_name)
            revoke_default_table_privileges(schema, role_name)
            revoke_existing_table_privileges(schema, role_name)
            revoke_existing_sequence_privileges(schema, role_name)
          end

          private

          def revoke_schema_migration_table_privileges(schema, role_name)
            statement = <<~SQL
              REVOKE ALL PRIVILEGES ON TABLE #{schema}.schema_migrations FROM #{role_name};
            SQL
            execute_sql!(statement)
          end

          def revoke_schema_usage(schema, role_name)
            execute_sql!(revoke_schema_usage_sql(schema, role_name))
          end

          def revoke_default_sequence_privileges(schema, role_name)
            execute_sql!(revoke_default_sequence_privileges_sql(schema, role_name))
          end

          def revoke_default_table_privileges(schema, role_name)
            execute_sql!(revoke_default_table_privileges_sql(schema, role_name))
          end

          def revoke_existing_table_privileges(schema, role_name)
            execute_sql!(revoke_existing_table_privileges_sql(schema, role_name))
          end

          def revoke_existing_sequence_privileges(schema, role_name)
            execute_sql!(revoke_existing_sequence_privileges_sql(schema, role_name))
          end

          def grant_schema_migration_table_privileges(schema, role_name)
            statement = <<~SQL
              DO $$ BEGIN
                IF EXISTS (
                  SELECT FROM pg_catalog.pg_tables WHERE schemaname = '#{schema}' AND tablename = 'schema_migrations'
                ) THEN
                 GRANT ALL PRIVILEGES ON TABLE #{schema}.schema_migrations TO #{role_name};
                END IF;
              END $$;
            SQL
            execute_sql!(statement)
          end

          def grant_schema_usage(schema, role_name)
            statement = <<~SQL
              GRANT USAGE ON SCHEMA #{schema} TO #{role_name};
            SQL
            execute_sql!(statement)
          end

          def grant_default_sequence_privileges(schema, role_name)
            statement = <<~SQL
              ALTER DEFAULT PRIVILEGES IN SCHEMA #{schema}
                GRANT USAGE, SELECT ON SEQUENCES TO #{role_name};
            SQL
            execute_sql!(statement)
          end

          def grant_default_table_privileges(schema, role_name)
            statement = <<~SQL
              ALTER DEFAULT PRIVILEGES IN SCHEMA #{schema}
                GRANT SELECT, INSERT, UPDATE, DELETE ON TABLES TO #{role_name};
            SQL
            execute_sql!(statement)
          end

          def grant_existing_table_privileges(schema, role_name)
            statement = <<~SQL
              GRANT SELECT, INSERT, UPDATE, DELETE
                ON ALL TABLES IN SCHEMA #{schema} TO #{role_name};
            SQL
            execute_sql!(statement)
          end

          def grant_existing_sequence_privileges(schema, role_name)
            statement = <<~SQL
              GRANT USAGE, SELECT
                ON ALL SEQUENCES IN SCHEMA #{schema} TO #{role_name};
            SQL
            execute_sql!(statement)
          end

          def revoke_schema_usage_sql(schema, role_name)
            statement = <<~SQL
              REVOKE USAGE ON SCHEMA #{schema} FROM #{role_name};
            SQL

            role_applicable_sql_statement(role_name, statement)
          end

          def revoke_default_sequence_privileges_sql(schema, role_name)
            statement = <<~SQL
              ALTER DEFAULT PRIVILEGES IN SCHEMA #{schema}
                REVOKE USAGE, SELECT ON SEQUENCES FROM #{role_name};
            SQL

            role_applicable_sql_statement(role_name, statement)
          end

          def revoke_default_table_privileges_sql(schema, role_name)
            statement = <<~SQL
              ALTER DEFAULT PRIVILEGES IN SCHEMA #{schema}
                REVOKE SELECT, INSERT, UPDATE, DELETE ON TABLES FROM #{role_name};
            SQL

            role_applicable_sql_statement(role_name, statement)
          end

          def revoke_existing_table_privileges_sql(schema, role_name)
            statement = <<~SQL
              REVOKE SELECT, INSERT, UPDATE, DELETE
                ON ALL TABLES IN SCHEMA #{schema} FROM #{role_name};
            SQL

            role_applicable_sql_statement(role_name, statement)
          end

          def revoke_existing_sequence_privileges_sql(schema, role_name)
            statement = <<~SQL
              REVOKE USAGE, SELECT
                ON ALL SEQUENCES IN SCHEMA #{schema} FROM #{role_name};
            SQL

            role_applicable_sql_statement(role_name, statement)
          end

          def role_applicable_sql_statement(role_name, statement)
            <<~SQL
              DO $do$ BEGIN
                IF EXISTS (SELECT FROM pg_catalog.pg_roles WHERE rolname = '#{role_name}') THEN
                  #{statement}
                END IF;
              END $do$;
            SQL
          end
        end
      end
    end
  end
end
