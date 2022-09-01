# frozen_string_literal: true

require 'active_record'
require 'forwardable'
require_relative 'pg_rls/version'
require_relative 'pg_rls/database/prepared'
require_relative 'pg_rls/schema/statements'
require_relative 'pg_rls/tenant'
require_relative 'pg_rls/secure_connection'
require_relative 'pg_rls/multi_tenancy'
require_relative 'pg_rls/railtie' if defined?(Rails)
require_relative 'pg_rls/errors/tenant_not_found'

# PostgreSQL Row Level Security
module PgRls
  class Error < StandardError; end
  SECURE_USERNAME = 'app_user'

  class << self
    extend Forwardable

    WRITER_METHODS = %i[table_name class_name search_methods establish_default_connection].freeze
    READER_METHODS = %i[
      connection_class database_configuration execute table_name class_name search_methods establish_default_connection
    ].freeze
    DELEGATORS_METHODS = %i[
      connection_class database_configuration execute table_name search_methods
      class_name all_tenants main_model establish_default_connection
    ].freeze

    attr_writer(*WRITER_METHODS)
    attr_reader(*READER_METHODS)

    def_delegators(*DELEGATORS_METHODS)

    def setup
      yield self
    end

    def database_connection_file
      file = File.read(Rails.root.join('config', 'database.yml'))

      YAML.safe_load(ERB.new(file).result, aliases: true)
    end

    def connection_class
      @connection_class ||= ActiveRecord::Base
    end

    def establish_new_connection
      ActiveRecord::Base.connection.disconnect! if ActiveRecord::Base.connection_pool.connected?

      connection_class.establish_connection(**database_configuration)
    end

    def admin_execute(query = nil)
      self.as_db_admin = true
      establish_new_connection
      return yield if block_given?

      execute(query)
    ensure
      self.as_db_admin = false
      establish_new_connection
    end

    def establish_default_connection=(value)
      ENV['AS_DB_ADMIN'] = value.to_s
      @default_connection = value
    end

    def default_connection?
      as_db_admin
    end

    def main_model
      class_name.to_s.camelize.constantize
    end

    def all_tenants
      main_model.all.each do |tenant|
        allowed_search_fields = search_methods.map(&:to_s).intersection(main_model.column_names)
        Tenant.switch tenant.send(allowed_search_fields.first)

        yield(tenant) if block_given?
      end
    end

    def current_connection_username
      connection_class.connection_db_config.configuration_hash[:username]
    end

    def execute(query)
      ActiveRecord::Migration.execute(query)
    end

    def database_default_configuration
      connection_class.connection.pool.db_config.configuration_hash
    rescue ActiveRecord::NoDatabaseError
      connection_class.connection_db_config.configuration_hash
    end

    def database_admin_configuration
      environment_db_configuration = database_connection_file[Rails.env]

      return environment_db_configuration if environment_db_configuration['username'].present?

      environment_db_configuration.first.last
    end

    def database_configuration
      return database_admin_configuration if default_connection?

      current_configuration = database_default_configuration.deep_dup
      current_configuration.tap do |config|
        config[:username] = PgRls.username
        config[:password] = PgRls.password
      end

      current_configuration.freeze
    end
  end

  mattr_accessor :as_db_admin
  @@as_db_admin = false

  mattr_accessor :table_name
  @@table_name = 'companies'

  mattr_accessor :class_name
  @@class_name = 'Company'

  mattr_accessor :username
  @@username = 'app_user'

  mattr_accessor :password
  @@password = 'password'

  mattr_accessor :search_methods
  @@search_methods = %i[subdomain id tenant_id]
end
