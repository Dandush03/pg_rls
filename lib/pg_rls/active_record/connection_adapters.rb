# frozen_string_literal: true

require_relative "connection_adapters/postgre_sql"
require_relative "connection_adapters/connection_pool"
require_relative "connection_adapters/rls_tenant"

module PgRls
  module ActiveRecord
    # ActiveRecord Connection Adapter Extension
    module ConnectionAdapters
    end
  end
end
