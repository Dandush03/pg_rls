# frozen_string_literal: true

module PgRls
  module Database
    # Prepare database for test unit
    module Prepared
      class << self
        def grant_user_credentials(name: PgRls::SECURE_USERNAME, password: 'password')
          return unless Rails.env.test? || PgRls.default_connection?

          PgRls.admin_execute <<-SQL
            DO
            $do$
            BEGIN
              IF NOT EXISTS (
                SELECT FROM pg_catalog.pg_roles AS r
                WHERE r.rolname = '#{name}') THEN

                  CREATE USER #{name} WITH PASSWORD '#{password}';
              END IF;
            END
            $do$;
            GRANT USAGE ON SCHEMA public TO #{name};
            ALTER DEFAULT PRIVILEGES IN SCHEMA public
              GRANT SELECT, INSERT, UPDATE, DELETE
              ON TABLES TO #{name};
            GRANT SELECT, INSERT, UPDATE, DELETE
              ON ALL TABLES IN SCHEMA public
              TO #{name};
            GRANT USAGE, SELECT
              ON ALL SEQUENCES IN SCHEMA public
              TO #{name};
          SQL
        end
      end
    end
  end
end
