# frozen_string_literal: true

module PgRls
  module ActiveRecord
    module ConnectionAdapters
      module PostgreSQL
        # This module contains the logic to validate user privileges
        module CheckRlsUserPrivilages # rubocop:disable Metrics/ModuleLength
          include SqlHelperMethod

          def check_rls_user_privileges!(role_name, schema)
            check_user_exists!(role_name) && check_user_in_rls_group!(role_name) &&
              check_schema_usage_privilege!("rls_group", schema) &&
              check_default_table_privileges!("rls_group",
                                              schema) && check_default_sequence_privileges!("rls_group", schema)
          end

          def check_table_privileges!(role_name, schema, table_name)
            execute_sql!(check_table_privileges_sql(role_name, schema, table_name))
            true
          rescue ::ActiveRecord::StatementInvalid => e
            raise UserMissingTablePrivilegesError, e.message
          end

          def check_sequence_privileges!(role_name, schema, sequence_name)
            execute_sql!(check_sequence_privileges_sql(role_name, schema, sequence_name))
            true
          rescue ::ActiveRecord::StatementInvalid => e
            raise UserMissingSequencePrivilegesError, e.message
          end

          private

          def check_user_exists!(role_name)
            execute_sql!(check_user_exists_sql(role_name))
            true
          rescue ::ActiveRecord::StatementInvalid => e
            raise UserDoesNotExistError, e.message
          end

          def check_user_in_rls_group!(role_name)
            execute_sql!(check_user_in_rls_group_sql(role_name))
            true
          rescue ::ActiveRecord::StatementInvalid => e
            raise UserNotInPgRlsGroupError, e.message
          end

          def check_schema_usage_privilege!(role_name, schema)
            execute_sql!(check_schema_usage_privilege_sql(role_name, schema))
            true
          rescue ::ActiveRecord::StatementInvalid => e
            raise UserMissingSchemaUsagePrivilegeError, e.message
          end

          def check_default_table_privileges!(role_name, schema)
            execute_sql!(check_default_table_privileges_sql(role_name, schema))
            true
          rescue ::ActiveRecord::StatementInvalid => e
            raise UserMissingTablePrivilegesError, e.message
          end

          def check_default_sequence_privileges!(role_name, schema)
            execute_sql!(check_default_sequence_privileges_sql(role_name, schema))
            true
          rescue ::ActiveRecord::StatementInvalid => e
            raise UserMissingSequencePrivilegesError, e.message
          end

          def check_user_exists_sql(role_name)
            <<~SQL
              DO $$ BEGIN
                IF NOT EXISTS (SELECT FROM pg_catalog.pg_roles WHERE rolname = '#{role_name}') THEN
                  RAISE EXCEPTION 'User % does not exist', '#{role_name}';
                END IF;
              END $$;
            SQL
          end

          def check_user_in_rls_group_sql(role_name)
            <<~SQL
              DO $$ BEGIN
                IF NOT EXISTS (
                  SELECT FROM pg_catalog.pg_auth_members
                    JOIN pg_roles AS rls_group ON rls_group.oid = pg_auth_members.roleid
                    JOIN pg_roles AS rls_member ON rls_member.oid = pg_auth_members.member
                    WHERE rls_group.rolname = 'rls_group' AND rls_member.rolname = '#{role_name}'
                ) THEN
                  RAISE EXCEPTION 'User % is not a member of pg_rls', '#{role_name}';
                END IF;
              END $$;
            SQL
          end

          # defacl.defaclobjtype = 'r' because r stands for relation (table, view), S stands for sequence
          # if needed more info visit https://www.postgresql.org/docs/9.6/catalog-pg-default-acl.html
          def check_schema_usage_privilege_sql(role_name, schema)
            <<~SQL
              DO $$
              BEGIN
                IF NOT EXISTS (
                  SELECT FROM pg_namespace n
                  LEFT JOIN LATERAL aclexplode(n.nspacl) acl ON true LEFT JOIN pg_roles grantee_roles ON acl.grantee = grantee_roles.oid
                  WHERE acl.privilege_type = 'USAGE' AND n.nspname = '#{schema}' AND grantee_roles.rolname = '#{role_name}'
                ) THEN
                  RAISE EXCEPTION 'User % is missing USAGE privilege on schema %', '#{role_name}', '#{schema}';
                END IF;
              END $$;
            SQL
          end

          def check_default_table_privileges_sql(role_name, schema)
            <<~SQL
              DO $$ BEGIN
                IF NOT EXISTS (
                  SELECT FROM pg_default_acl defacl JOIN pg_namespace n ON defacl.defaclnamespace = n.oid LEFT JOIN LATERAL aclexplode(defacl.defaclacl) acl ON true
                  LEFT JOIN pg_roles r_grantee ON r_grantee.oid = acl.grantee WHERE r_grantee.rolname = '#{role_name}' AND n.nspname = 'public' AND defacl.defaclobjtype = 'r'
                  AND acl.privilege_type IN ('SELECT', 'INSERT', 'UPDATE', 'DELETE') GROUP BY n.nspname, defacl.defaclobjtype, r_grantee.rolname HAVING COUNT(DISTINCT acl.privilege_type) = 4
                ) THEN
                  RAISE EXCEPTION 'User % is missing one or more of SELECT, INSERT, UPDATE, DELETE privileges on tables in schema %', '#{role_name}', '#{schema}';
                END IF;
              END $$;
            SQL
          end

          def check_table_privileges_sql(role_name, schema, table_name)
            <<~SQL
              DO $$ BEGIN
                IF NOT EXISTS (
                  SELECT FROM pg_class c JOIN pg_namespace n ON c.relnamespace = n.oid LEFT JOIN LATERAL aclexplode(c.relacl) acl ON true LEFT JOIN pg_roles r_grantee ON r_grantee.oid = acl.grantee
                  WHERE r_grantee.rolname = '#{role_name}' AND n.nspname = '#{schema}' AND c.relname = '#{table_name}' AND acl.privilege_type IN ('SELECT', 'INSERT', 'UPDATE', 'DELETE')
	                GROUP BY n.nspname, c.relname, r_grantee.rolname HAVING COUNT(DISTINCT acl.privilege_type) = 4
                ) THEN
                  RAISE EXCEPTION 'User % is missing one or more of SELECT, INSERT, UPDATE, DELETE privileges on table % in schema %', '#{role_name}', '#{table_name}', '#{schema}';
                END IF;
              END $$;
            SQL
          end

          def check_default_sequence_privileges_sql(role_name, schema)
            <<~SQL
              DO $$ BEGIN
                IF NOT EXISTS (
                  SELECT FROM pg_default_acl defacl JOIN pg_namespace n ON defacl.defaclnamespace = n.oid LEFT JOIN LATERAL aclexplode(defacl.defaclacl) acl ON true
                  LEFT JOIN pg_roles r_grantee ON r_grantee.oid = acl.grantee WHERE r_grantee.rolname = '#{role_name}' AND n.nspname = 'public' AND defacl.defaclobjtype = 'S'
                  AND acl.privilege_type IN ('SELECT', 'USAGE') GROUP BY n.nspname, defacl.defaclobjtype, r_grantee.rolname HAVING COUNT(DISTINCT acl.privilege_type) = 2
                ) THEN
                  RAISE EXCEPTION 'User % is missing USAGE and/or SELECT privileges on sequences in schema %', '#{role_name}', '#{schema}';
                END IF; END $$;
            SQL
          end

          def check_sequence_privileges_sql(role_name, schema, sequence_name)
            <<~SQL
              DO $$ BEGIN
                IF NOT EXISTS (
                  SELECT FROM pg_class c JOIN pg_namespace n ON c.relnamespace = n.oid LEFT JOIN LATERAL aclexplode(c.relacl) acl ON true LEFT JOIN pg_roles r_grantee ON r_grantee.oid = acl.grantee
                  WHERE r_grantee.rolname = '#{role_name}' AND n.nspname = '#{schema}' AND c.relname = '#{sequence_name}' AND acl.privilege_type IN ('SELECT', 'USAGE')
                  GROUP BY n.nspname, c.relname, r_grantee.rolname HAVING COUNT(DISTINCT acl.privilege_type) = 2
                ) THEN
                  RAISE EXCEPTION 'User % is missing USAGE and/or SELECT privileges on sequence % in schema %', '#{role_name}', '#{sequence_name}', '#{schema}';
                END IF;
              END $$;
            SQL
          end
        end
      end
    end
  end
end

ActiveRecord::ConnectionAdapters::AbstractAdapter.include(
  PgRls::ActiveRecord::ConnectionAdapters::PostgreSQL::CheckRlsUserPrivilages
)
