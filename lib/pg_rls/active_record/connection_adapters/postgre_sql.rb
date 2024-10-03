# frozen_string_literal: true

require_relative "postgre_sql/errors"
require_relative "postgre_sql/sql_helper_method"
require_relative "postgre_sql/rls_functions"
require_relative "postgre_sql/rls_triggers"
require_relative "postgre_sql/rls_user_statements"
require_relative "postgre_sql/check_rls_user_privilages"
require_relative "postgre_sql/grant_rls_user_privilages"

module PgRls
  module ActiveRecord
    module ConnectionAdapters
      # ActiveRecord PostgreSQL Connection Adapter Extension
      module PostgreSQL
      end
    end
  end
end
