# frozen_string_literal: true

module PgRls
  module Database
    # Prepare database for test unit
    module Prepared
      class << self
        def grant_user_credentials(name: PgRls.username, schema: 'public')
          PgRls.admin_execute <<-SQL.squish
            DO
            $do$
            BEGIN
              IF NOT EXISTS (
                SELECT table_catalog, table_schema, table_name, privilege_type
                  FROM   information_schema.table_privileges
                  WHERE  grantee = '#{name}'
              ) THEN
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
                END IF;
            END;
            $do$;
          SQL
        end
      end
    end
  end
end
