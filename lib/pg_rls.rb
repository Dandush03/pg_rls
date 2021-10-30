# frozen_string_literal: true

require 'active_record'
require 'forwardable'
require_relative 'pg_rls/version'
require_relative 'pg_rls/test/prepared_database'
require_relative 'pg_rls/schema/statements'
require_relative 'pg_rls/tenant'
require_relative 'pg_rls/secure_connection'
require_relative 'pg_rls/multi_tenancy'

# PostgreSQL Row Level Security
module PgRls
  class Error < StandardError; end
  SECURE_USERNAME = "#{Rails.env}_app_user".freeze

  class << self
    extend Forwardable

    WRITER_METHODS = %i[table_name class_name].freeze
    READER_METHODS = %i[
      connection_class database_configuration execute table_name class_name
    ].freeze
    DELEGATORS_METHODS = %i[
      connection_class database_configuration execute table_name class_name
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

    def current_connection_username
      PgRls.connection_class.connection_db_config.configuration_hash[:username]
    end

    def execute(query)
      @execute = ActiveRecord::Migration.execute(query)
    end

    def database_configuration
      @database_configuration ||= database_connection_file[Rails.env].tap do |config|
        config['username'] = PgRls::SECURE_USERNAME
      end
    end
  end
  mattr_accessor :table_name
  @@table_name = 'companies'

  mattr_accessor :class_name
  @@class_name = 'Company'
end
