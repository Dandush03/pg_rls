# frozen_string_literal: true

module PgRls
  module Schema
    # Down Schema Statements
    module DownStatements
      def drop_rls_user
        ActiveRecord::Migration.execute <<~SQL
          DROP OWNED BY #{PgRls::SECURE_USERNAME};
          REVOKE ALL PRIVILEGES ON ALL TABLES IN SCHEMA public FROM #{PgRls::SECURE_USERNAME};
          REVOKE ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public FROM #{PgRls::SECURE_USERNAME};
          REVOKE ALL PRIVILEGES ON ALL FUNCTIONS IN SCHEMA public FROM #{PgRls::SECURE_USERNAME};
          DROP USER #{PgRls::SECURE_USERNAME};
        SQL
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

      def drop_rls_policy(table_name)
        ActiveRecord::Migration.execute <<-SQL
          DROP POLICY #{table_name}_#{PgRls::SECURE_USERNAME} ON #{table_name};
          ALTER TABLE #{table_name} DISABLE ROW LEVEL SECURITY;
        SQL
      end
    end
  end
end
