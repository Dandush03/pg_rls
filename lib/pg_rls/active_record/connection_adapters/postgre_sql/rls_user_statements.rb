# frozen_string_literal: true

module PgRls
  module ActiveRecord
    module ConnectionAdapters
      module PostgreSQL
        # This module contains the logic to grant user privileges
        module RlsUserStatements
          include SqlHelperMethod

          def create_rls_role(name, password)
            create_rls_user(name, password)
            assign_user_to_group(name)
          end

          def drop_rls_role(name)
            remove_user_from_group(name)
            drop_rls_user(name)
          end

          def user_exists?(name)
            execute_sql!(user_exists_sql(name)).first.present?
          end

          def drop_rls_user(name)
            execute_sql!(drop_rls_user_sql(name))
          end

          def create_rls_user(name, password)
            execute_sql!(create_rls_user_sql(name, password))
          end

          def create_rls_group
            execute_sql!(create_rls_group_sql)
          end

          def drop_rls_group
            execute_sql!(drop_rls_group_sql)
          end

          def assign_user_to_group(name)
            execute_sql!(assign_user_to_group_sql(name))
          end

          def remove_user_from_group(name)
            execute_sql!(remove_user_from_group_sql(name))
          end

          private

          def user_exists_sql(name)
            <<~SQL
              SELECT 1
              FROM pg_catalog.pg_roles
              WHERE rolname = '#{name}';
            SQL
          end

          def drop_rls_user_sql(name)
            <<~SQL
              DO $do$ BEGIN
                IF EXISTS (SELECT FROM pg_catalog.pg_roles WHERE rolname = '#{name}') THEN
                  DROP ROLE #{name};
                END IF; END $do$;
            SQL
          end

          def create_rls_user_sql(name, password)
            <<~SQL
              DO $do$ BEGIN
                IF NOT EXISTS (SELECT FROM pg_catalog.pg_roles WHERE rolname = '#{name}') THEN
                  CREATE ROLE #{name} LOGIN PASSWORD '#{password}';
                END IF;
              END $do$;
            SQL
          end

          def create_rls_group_sql
            <<~SQL
              DO $do$ BEGIN
                IF NOT EXISTS (SELECT FROM pg_catalog.pg_roles WHERE rolname = 'rls_group') THEN
                  CREATE ROLE rls_group NOLOGIN;
                END IF;
              END $do$;
            SQL
          end

          def drop_rls_group_sql
            <<~SQL
              DO $do$ BEGIN
                IF EXISTS (SELECT FROM pg_catalog.pg_roles WHERE rolname = 'rls_group') THEN
                  DROP ROLE rls_group;
                END IF;
              END $do$;
            SQL
          end

          def assign_user_to_group_sql(name)
            <<~SQL
              DO $$ BEGIN IF NOT EXISTS (
                  SELECT FROM pg_catalog.pg_auth_members
                    JOIN pg_roles AS rls_group ON rls_group.oid = pg_auth_members.roleid
                    JOIN pg_roles AS rls_member ON rls_member.oid = pg_auth_members.member
                    WHERE rls_group.rolname = 'rls_group' AND rls_member.rolname = '#{name}'
                ) THEN
                  GRANT rls_group TO #{name};
                END IF; END $$;
            SQL
          end

          def remove_user_from_group_sql(name)
            <<~SQL
              DO $$ BEGIN IF EXISTS (
                  SELECT FROM pg_catalog.pg_auth_members
                    JOIN pg_roles AS rls_group ON rls_group.oid = pg_auth_members.roleid
                    JOIN pg_roles AS rls_member ON rls_member.oid = pg_auth_members.member
                    WHERE rls_group.rolname = 'rls_group' AND rls_member.rolname = '#{name}'
                ) THEN
                  REVOKE rls_group FROM #{name};
                END IF; END $$;
            SQL
          end
        end
      end
    end
  end
end
