# frozen_string_literal: true

module PgRls
  module Schema
    module Solo
      # Up Schema Solo Statements
      module UpStatements
        def setup_rls_tenant_table
          ActiveRecord::Migration.execute <<-SQL
            DO
            $do$
              BEGIN
                IF NOT EXISTS (
                  SELECT FROM pg_tables
                  WHERE schemaname = 'public' AND tablename = '#{PgRls.table_name}') THEN
                    #{create_rls_user}
                    #{create_rls_setter_function}
                    #{create_rls_blocking_function}
                    #{create_rls_solo_tenant_table}
                    #{append_blocking_function}
                END IF;
              END;
            $do$;
          SQL
        end

        def create_rls_user(name: PgRls.username, password: PgRls.password, schema: 'public')
          <<~SQL
            -- Grant Role Permissions
            BEGIN
              IF NOT EXISTS (
                SELECT FROM pg_catalog.pg_roles  -- SELECT list can be empty for this
                WHERE  rolname = '#{name}') THEN

                CREATE USER #{name} WITH PASSWORD '#{password}';
              END IF;
              GRANT ALL PRIVILEGES ON TABLE schema_migrations TO #{name};
              GRANT USAGE ON SCHEMA #{schema} TO #{name};
              ALTER DEFAULT PRIVILEGES IN SCHEMA #{schema}
                GRANT USAGE, SELECT
                ON SEQUENCES TO #{name};
              ALTER DEFAULT PRIVILEGES IN SCHEMA #{schema}
                GRANT SELECT, INSERT, UPDATE, DELETE
                ON TABLES TO #{name};
              GRANT SELECT, INSERT, UPDATE, DELETE
                ON ALL TABLES IN SCHEMA #{schema}
                TO #{name};
              GRANT USAGE, SELECT
                ON ALL SEQUENCES IN SCHEMA #{schema}
                TO #{name};
            END;
          SQL
        end

        def create_rls_setter_function
          <<~SQL
            -- Create RLS Setter Function
            CREATE OR REPLACE FUNCTION tenant_id_setter ()
              RETURNS TRIGGER LANGUAGE plpgsql AS $$
                BEGIN
                  IF NOT EXISTS (
                    SELECT FROM #{PgRls.table_name}
                      WHERE tenant_id = (current_setting('rls.tenant_id'))::uuid
                  ) THEN
                    INSERT INTO #{PgRls.table_name} (tenant_id)
                      VALUES ((current_setting('rls.tenant_id'))::uuid);
                  END IF;

                  NEW.tenant_id:= (current_setting('rls.tenant_id'));
                  RETURN NEW;
                END $$;
          SQL
        end

        def create_rls_blocking_function
          <<~SQL
            -- Create RLS Blocking Function
            CREATE OR REPLACE FUNCTION id_safe_guard ()
              RETURNS TRIGGER LANGUAGE plpgsql AS $$
                BEGIN
                  RAISE EXCEPTION 'This column is guarded due to tenancy dependency';
                END $$;
          SQL
        end

        def create_rls_solo_tenant_table
          <<~SQL
            -- Create Tenant Table
            CREATE TABLE #{PgRls.table_name} (
              tenant_id uuid PRIMARY KEY
            );
          SQL
        end

        def append_blocking_function
          <<~SQL
            -- Append Blocking Function
            CREATE TRIGGER id_safe_guard
              BEFORE UPDATE OF tenant_id ON #{PgRls.table_name}
                FOR EACH ROW EXECUTE PROCEDURE id_safe_guard();
          SQL
        end
      end
    end
  end
end
