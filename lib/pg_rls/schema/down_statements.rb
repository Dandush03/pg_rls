# frozen_string_literal: true

module PgRls
  module Schema
    # Down Schema Statements
    module DownStatements
      def drop_rls_user(name = :app_user)
        ActiveRecord::Migration.execute "DROP USER #{name};"
      end

      def drop_rls_blocking_function
        ActiveRecord::Migration.execute 'DROP FUNCTION IF EXISTS id_safe_guard ();'
      end

      def drop_rls_setter_function
        ActiveRecord::Migration.execute 'DROP FUNCTION IF EXISTS tenant_id_setter ();'
      end

      def detach_blocking_function(table_name)
        ActiveRecord::Migration.execute <<-SQL
          DROP TRIGGER IF EXISTS id_safe_guard
            ON #{table_name};
        SQL
      end

      def detach_trigger_function(table_name)
        ActiveRecord::Migration.execute <<-SQL
          DROP TRIGGER IF EXISTS tenant_id_setter
            ON #{table_name};
        SQL
      end

      def drop_rls_column(table_name)
        ActiveRecord::Migration.execute <<-SQL
          ALTER TABLE #{table_name}
            DROP COLUMN IF EXISTS tenant_id;
        SQL
      end

      def drop_rls_policy(table_name, user = :app_user)
        ActiveRecord::Migration.execute <<-SQL
          DROP POLICY #{table_name}_#{user} ON #{table_name};
          ALTER TABLE #{table_name} DISABLE ROW LEVEL SECURITY;
        SQL
      end
    end
  end
end
