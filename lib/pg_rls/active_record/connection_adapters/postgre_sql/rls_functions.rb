# frozen_string_literal: true

module PgRls
  module ActiveRecord
    module ConnectionAdapters
      module PostgreSQL
        # This module contains the logic to create, drop and validate RLS functions
        module RlsFunctions
          include SqlHelperMethod

          def function_exists?(function_name)
            query = <<~SQL
              SELECT 1
              FROM pg_proc
              WHERE proname = '#{function_name}'
            SQL

            execute_sql!(query).any?
          end

          def create_rls_functions
            create_rls_exception
            create_tenant_id_setter_function
            create_tenant_id_update_blocker_function
          end

          def drop_rls_functions
            drop_function("tenant_id_setter")
            drop_function("rls_exception")
            drop_function("tenant_id_update_blocker")
          end

          private

          def create_function(name, body)
            query = <<~SQL
              CREATE OR REPLACE FUNCTION #{name}()
                RETURNS TRIGGER LANGUAGE plpgsql AS $$
                #{body}
                $$;
            SQL

            execute_sql!(query)
          end

          def drop_function(name)
            query = <<~SQL
              DROP FUNCTION IF EXISTS #{name}() CASCADE;
            SQL

            execute_sql!(query)
          end

          def create_rls_exception
            body = <<~SQL
              BEGIN
                RAISE EXCEPTION 'This column is guarded due to tenancy dependency';
              END
            SQL

            create_function("rls_exception", body)
          end

          def create_tenant_id_setter_function
            body = <<~SQL
              BEGIN
                new.tenant_id:= (current_setting('rls.tenant_id'));
                RETURN new;
              END;
            SQL

            create_function("tenant_id_setter", body)
          end

          def create_tenant_id_update_blocker_function
            body = <<~SQL
              BEGIN
                IF OLD.tenant_id IS NOT NULL AND NEW.tenant_id != OLD.tenant_id THEN
                  RAISE EXCEPTION 'Updating tenant_id is not allowed';
                END IF;
                RETURN NEW;
              END;
            SQL

            create_function("tenant_id_update_blocker", body)
          end
        end
      end
    end
  end
end
