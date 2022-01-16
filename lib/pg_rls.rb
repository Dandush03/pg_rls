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

# PostgreSQL Row Level Security
module PgRls
  class Error < StandardError; end
  SECURE_USERNAME = "#{Rails.env}_app_user".freeze

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
    # Your code goes here...
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
      connection_class.establish_connection(
        **database_configuration
      )
    end

    def admin_execute(query = nil)
      self.establish_default_connection = true
      establish_new_connection
      return yield if block_given?

      execute(query)
    ensure
      self.establish_default_connection = false
      establish_new_connection
    end

    def establish_default_connection=(value)
      ENV['AS_DB_ADMIN'] = value.to_s
      @default_connection = value
    end

    def default_connection?
      @default_connection
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

    def database_configuration
      database_connection_file[Rails.env].tap do |config|
        config['username'] = PgRls::SECURE_USERNAME unless default_connection?
      end
    end
  end
  mattr_accessor :table_name
  @@table_name = 'companies'

  mattr_accessor :class_name
  @@class_name = 'Company'

  mattr_accessor :search_methods
  @@search_methods = %i[subdomain id tenant_id]
end
