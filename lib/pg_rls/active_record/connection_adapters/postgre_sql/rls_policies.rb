# frozen_string_literal: true

module PgRls
  module ActiveRecord
    module ConnectionAdapters
      module PostgreSQL
        # This module contains the logic to grant user privileges
        module RlsPolicies
          include SqlHelperMethod

          def enable_table_rls(table_name, user)
            execute_sql!(create_rls_policy_sql(table_name, user))
            execute_sql!(enable_row_level_security_sql(table_name))
          end

          def disable_table_rls(table_name, user)
            execute_sql!(drop_rls_policy_sql(table_name, user))
            execute_sql!(disable_row_level_security_sql(table_name))
          end

          private

          def drop_rls_policy_sql(table_name, user)
            <<~SQL
              DROP POLICY IF EXISTS #{table_name}_#{user}
                ON #{table_name};
            SQL
          end

          def disable_row_level_security_sql(table_name)
            <<~SQL
              ALTER TABLE IF EXISTS #{table_name}
                DISABLE ROW LEVEL SECURITY;
            SQL
          end

          def create_rls_policy_sql(table_name, user)
            <<~SQL
              CREATE POLICY #{table_name}_#{user}
                ON #{table_name}
                TO #{user}
                USING (tenant_id = NULLIF(current_setting('rls.tenant_id', TRUE), '')::uuid);
            SQL
          end

          def enable_row_level_security_sql(table_name)
            <<~SQL
              ALTER TABLE #{table_name}
                ENABLE ROW LEVEL SECURITY;
            SQL
          end
        end
      end
    end
  end
end
