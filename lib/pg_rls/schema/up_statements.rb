# frozen_string_literal: true

module PgRls
  module Schema
    # Up Schema Statements
    module UpStatements
      def create_rls_user(name: PgRls.username, password: PgRls.password, schema: 'public')
        ActiveRecord::Migration.execute <<-SQL
          DO
          $do$
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
          $do$;
        SQL
      end

      def create_rls_blocking_function
        ActiveRecord::Migration.execute <<-SQL.squish
          CREATE OR REPLACE FUNCTION id_safe_guard ()
            RETURNS TRIGGER LANGUAGE plpgsql AS $$
              BEGIN
                RAISE EXCEPTION 'This column is guarded due to tenancy dependency';
              END $$;
        SQL
      end

      def create_rls_setter_function
        ActiveRecord::Migration.execute <<-SQL.squish
          CREATE OR REPLACE FUNCTION tenant_id_setter ()
            RETURNS TRIGGER LANGUAGE plpgsql AS $$
              BEGIN
                new.tenant_id:= (current_setting('rls.tenant_id'));
                RETURN new;
              END $$;
        SQL
      end

      def append_blocking_function(table_name)
        ActiveRecord::Migration.execute <<-SQL.squish
          CREATE TRIGGER id_safe_guard
            BEFORE UPDATE OF id ON #{table_name}
              FOR EACH ROW EXECUTE PROCEDURE id_safe_guard();
        SQL
      end

      def append_trigger_function(table_name)
        ActiveRecord::Migration.execute <<-SQL.squish
          CREATE TRIGGER tenant_id_setter
            BEFORE INSERT OR UPDATE ON #{table_name}
              FOR EACH ROW EXECUTE PROCEDURE tenant_id_setter();
        SQL
      end

      def add_rls_column_to_tenant_table(table_name)
        ActiveRecord::Migration.execute <<-SQL.squish
          ALTER TABLE #{table_name}
            ADD COLUMN IF NOT EXISTS
              tenant_id uuid UNIQUE DEFAULT gen_random_uuid();
        SQL
      end

      def add_rls_column(table_name)
        ActiveRecord::Migration.execute <<-SQL.squish
          ALTER TABLE #{table_name}
            ADD COLUMN IF NOT EXISTS tenant_id uuid,
            ADD CONSTRAINT fk_#{PgRls.table_name}
              FOREIGN KEY (tenant_id)
              REFERENCES #{PgRls.table_name}(tenant_id)
              ON DELETE CASCADE;
        SQL
      end

      def create_rls_policy(table_name, user = PgRls.username)
        ActiveRecord::Migration.execute <<-SQL.squish
          ALTER TABLE #{table_name} ENABLE ROW LEVEL SECURITY;
          CREATE POLICY #{table_name}_#{user}
            ON #{table_name}
            TO #{user}
            USING (tenant_id = NULLIF(current_setting('rls.tenant_id', TRUE), '')::uuid);
        SQL
      end
    end
  end
end
