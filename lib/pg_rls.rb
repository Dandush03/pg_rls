# frozen_string_literal: true

require 'active_record'
require 'forwardable'
require_relative 'pg_rls/version'
require_relative 'pg_rls/database/prepared'
require_relative 'pg_rls/schema/statements'
require_relative 'pg_rls/database/configurations'
require_relative 'pg_rls/database/admin_statements'
require_relative 'pg_rls/tenant'
require_relative 'pg_rls/multi_tenancy'
require_relative 'pg_rls/railtie' if defined?(Rails)
require_relative 'pg_rls/errors/index'

ActiveRecord::Migrator.prepend PgRls::Admin::ActiveRecord::Migrator
ActiveRecord::Tasks::DatabaseTasks.prepend PgRls::Admin::ActiveRecord::Tasks::DatabaseTasks
ActiveRecord::ConnectionAdapters::AbstractAdapter.include PgRls::Schema::Statements
# PostgreSQL Row Level Security
module PgRls
  class Error < StandardError; end
  class << self
    extend Forwardable

    WRITER_METHODS = %i[table_name class_name search_methods].freeze
    READER_METHODS = %i[connection_class execute table_name class_name search_methods].freeze
    DELEGATORS_METHODS = %i[connection_class execute table_name search_methods class_name main_model].freeze

    attr_writer(*WRITER_METHODS)
    attr_reader(*READER_METHODS)

    def_delegators(*DELEGATORS_METHODS)

    def setup
      ActiveRecord::Base.ignored_columns += %w[tenant_id]

      yield self
      PgRls.main_model.ignored_columns = []
    end

    def connection_class
      @connection_class ||= ActiveRecord::Base
    end

    def admin_execute(query = nil, &)
      current_tenant, reset_rls_connection = establish_admin_connection
      execute_query_or_block(query, &)
    ensure
      reset_connection_if_needed(current_tenant, reset_rls_connection)
    end

    def establish_new_connection!(admin: false)
      self.as_db_admin = admin

      db_config = PgRls.main_model.connection_db_config.configuration_hash
      execute_rls_in_shards do |connection_class, pool|
        connection_class.connection_pool.disconnect!
        connection_class.remove_connection
        connection_class.establish_connection(pool.db_config)
      end
    end

    def main_model
      class_name.to_s.camelize.constantize
    end

    def on_each_tenant(&)
      with_rls_connection do
        result = []

        main_model.find_each do |tenant|
          allowed_search_fields = search_methods.map(&:to_s).intersection(main_model.column_names)
          Tenant.switch tenant.send(allowed_search_fields.first)

          result << { tenant:, result: ensure_block_execution(tenant, &) }
        end

        PgRls::Tenant.reset_rls!

        result
      end
    end

    def execute_rls_in_shards
      connection_pool_list = PgRls.connection_class.connection_handler.connection_pool_list
      result = []

      connection_pool_list.each do |pool|
        pool.connection.transaction do
          Rails.logger.info("Executing in #{pool.connection.connection_class}")

          result << yield(pool.connection.connection_class, pool)
        end
      end

      result
    end

    def current_db_username
      ActiveRecord::Base.connection_db_config.configuration_hash[:username]
    end

    def as_db_admin?
      @as_db_admin || false
    end

    def admin_connection?
      current_db_username != username
    end

    private

    attr_writer :as_db_admin

    def with_rls_connection(&)
      reset_connection = admin_connection?

      establish_new_connection! if reset_connection
      ensure_block_execution(&)
    ensure
      establish_new_connection!(admin: true) if reset_connection
    end

    def establish_admin_connection
      reset_rls_connection = false
      current_tenant = nil

      unless admin_connection?
        reset_rls_connection = true
        current_tenant = PgRls::Tenant.fetch
        establish_new_connection!(admin: true)
      end

      [current_tenant, reset_rls_connection]
    end

    def ensure_block_execution(*, **)
      yield(*, **).presence
    end

    def execute_query_or_block(query = nil, &)
      if block_given?
        ensure_block_execution(&)
      else
        execute(query)
      end
    end

    def reset_connection_if_needed(current_tenant, reset_rls_connection)
      return unless reset_rls_connection

      establish_new_connection!
      PgRls::Tenant.switch(current_tenant) if current_tenant.present?
    end
  end

  mattr_accessor :table_name
  @@table_name = 'companies'

  mattr_accessor :class_name
  @@class_name = 'Company'

  mattr_accessor :username
  @@username = 'app_user'

  mattr_accessor :password
  @@password = 'password'

  mattr_accessor :test_inline_tenant
  @@test_inline_tenant = false

  mattr_accessor :search_methods
  @@search_methods = %i[subdomain id tenant_id]
end
