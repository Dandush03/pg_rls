# frozen_string_literal: true

module PgRls
  module Schema
    # Up Schema Statements
    module UpStatements
      def create_rls_user(name: :app_user, password: 'password')
        PgRls.execute <<-SQL
          DROP ROLE IF EXISTS #{name};
          CREATE USER #{name} WITH PASSWORD '#{password}';
          GRANT ALL PRIVILEGES ON TABLE schema_migrations TO #{name};
          ALTER DEFAULT PRIVILEGES IN SCHEMA public
            GRANT SELECT, INSERT, UPDATE, DELETE
            ON TABLES TO #{name};
        SQL
      end

      def create_rls_blocking_function
        ActiveRecord::Migration.execute <<-SQL
          CREATE OR REPLACE FUNCTION id_safe_guard ()
            RETURNS TRIGGER LANGUAGE plpgsql AS $$
              BEGIN
                RAISE EXCEPTION 'This column is guarded due to tenancy dependency';
              END $$;
        SQL
      end

      def create_rls_setter_function
        ActiveRecord::Migration.execute <<-SQL
          CREATE OR REPLACE FUNCTION tenant_id_setter ()
            RETURNS TRIGGER LANGUAGE plpgsql AS $$
              BEGIN
                new.tenant_id:= (current_setting('rls.tenant_id'));
                RETURN new;
              END $$;
        SQL
      end

      def append_blocking_function(table_name)
        ActiveRecord::Migration.execute <<-SQL
          CREATE TRIGGER id_safe_guard
            BEFORE UPDATE OF id ON #{table_name}
              FOR EACH ROW EXECUTE PROCEDURE id_safe_guard();
        SQL
      end

      def append_trigger_function(table_name)
        ActiveRecord::Migration.execute <<-SQL
          CREATE TRIGGER tenant_id_setter
            BEFORE INSERT OR UPDATE ON #{table_name}
              FOR EACH ROW EXECUTE PROCEDURE tenant_id_setter();
        SQL
      end

      def add_rls_column_to_tenant_table(table_name)
        ActiveRecord::Migration.execute <<-SQL
          ALTER TABLE #{table_name}
            ADD COLUMN IF NOT EXISTS
              tenant_id uuid UNIQUE DEFAULT gen_random_uuid();
        SQL
      end

      def add_rls_column(table_name)
        ActiveRecord::Migration.execute <<-SQL
          ALTER TABLE #{table_name}
            ADD COLUMN IF NOT EXISTS tenant_id uuid,
            ADD CONSTRAINT fk_companies
              FOREIGN KEY (tenant_id)
              REFERENCES companies(tenant_id)
              ON DELETE CASCADE;
        SQL
      end

      def create_rls_policy(table_name, user = :app_user)
        ActiveRecord::Migration.execute <<-SQL
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
