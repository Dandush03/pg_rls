# frozen_string_literal: true

require 'active_record'
require 'forwardable'
require_relative 'pg_rls/version'
require_relative 'pg_rls/database/prepared'
require_relative 'pg_rls/schema/statements'
require_relative 'pg_rls/database/configurations'
require_relative 'pg_rls/tenant'
require_relative 'pg_rls/multi_tenancy'
require_relative 'pg_rls/railtie' if defined?(Rails)
require_relative 'pg_rls/errors/index'

# PostgreSQL Row Level Security
module PgRls
  class Error < StandardError; end
  SECURE_USERNAME = 'app_user'

  class << self
    extend Forwardable

    WRITER_METHODS = %i[table_name class_name search_methods].freeze
    READER_METHODS = %i[
      connection_class execute table_name class_name search_methods
    ].freeze
    DELEGATORS_METHODS = %i[
      connection_class execute table_name search_methods
      class_name main_model
    ].freeze

    attr_writer(*WRITER_METHODS)
    attr_reader(*READER_METHODS)

    def_delegators(*DELEGATORS_METHODS)

    def setup
      ActiveRecord::ConnectionAdapters::AbstractAdapter.include PgRls::Schema::Statements
      ActiveRecord::Base.ignored_columns = %w[tenant_id]

      yield self
    end

    def connection_class
      @connection_class ||= ActiveRecord::Base
    end

    def admin_tasks_execute
      raise PgRls::Errors::RakeOnlyError if Rake.application.top_level_tasks.blank?

      self.as_db_admin = true

      yield
    rescue NoMethodError => error
      if error.message.include?('Rake:Module')
        raise PgRls::Errors::RakeOnlyError
      else
        raise error
      end
    ensure
      self.as_db_admin = false
    end

    def admin_execute(query = nil)
      current_tenant = PgRls::Tenant.fetch

      self.as_db_admin = true
      establish_new_connection!

      result = nil

      if block_given?
        result = yield
      else
        result = execute(query)
      end

      result if result.present?
    ensure
      self.as_db_admin = false
      establish_new_connection!
      PgRls::Tenant.switch!(current_tenant) if current_tenant.present?
    end

    def establish_new_connection!
      execute_rls_in_shards do |connection_class, pool|
        connection_class.remove_connection
        connection_class.establish_connection(
          pool.db_config
        )
      end
    end

    def main_model
      class_name.to_s.camelize.constantize
    end

    def on_each_tenant
      result = []
      main_model.find_each do |tenant|
        allowed_search_fields = search_methods.map(&:to_s).intersection(main_model.column_names)
        Tenant.switch tenant.send(allowed_search_fields.first)

        result << { tenant: tenant, result: yield(tenant) }
      end

      PgRls::Tenant.reset_rls!

      result
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

    private

    def as_db_admin=(value)
      @as_db_admin = value
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
