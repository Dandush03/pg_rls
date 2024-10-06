# frozen_string_literal: true

require "active_record/connection_adapters/postgresql_adapter"
require_relative "postgre_sql/errors"
require_relative "postgre_sql/sql_helper_method"
require_relative "postgre_sql/rls_functions"
require_relative "postgre_sql/rls_triggers"
require_relative "postgre_sql/rls_user_statements"
require_relative "postgre_sql/check_rls_user_privileges"
require_relative "postgre_sql/grant_rls_user_privileges"
require_relative "postgre_sql/rls_policies"

module PgRls
  module ActiveRecord
    module ConnectionAdapters
      # ActiveRecord PostgreSQL Connection Adapter Extension
      module PostgreSQL
        def self.included(base)
          # Dynamically include all modules into the adapter
          constants.each do |const_name|
            mod = const_get(const_name)
            base.include(mod) if mod.is_a?(Module) && !mod.is_a?(Class)
          end
        end
      end
    end
  end
end

ActiveRecord::ConnectionAdapters::PostgreSQL::SchemaStatements.include(
  PgRls::ActiveRecord::ConnectionAdapters::PostgreSQL
)
