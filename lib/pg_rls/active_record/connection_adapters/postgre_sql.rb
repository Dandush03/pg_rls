# frozen_string_literal: true

require_relative "postgre_sql/sql_helper_method"
require_relative "postgre_sql/rls_functions"
require_relative "postgre_sql/rls_triggers"

module PgRls
  module ActiveRecord
    module ConnectionAdapters
      # ActiveRecord PostgreSQL Connection Adapter Extension
      module PostgreSQL
      end
    end
  end
end
