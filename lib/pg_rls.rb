# frozen_string_literal: true

require 'active_record'
require 'forwardable'
require_relative 'pg_rls/version'
require_relative 'pg_rls/schema/statements'
require_relative 'pg_rls/tenant/tenant'

# PostgreSQL Row Level Security
module PgRls
  class Error < StandardError; end

  class << self
    extend Forwardable

    WRITER_METHODS = %i[].freeze
    READER_METHODS = %i[connection_class database_configuration execute].freeze
    DELEGATORS_METHODS = %i[connection_class database_configuration execute].freeze

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
        connection_class.connection_config.dup.tap { |n| n[:username] = 'app_user' }
      )
    end

    def execute(query)
      @execute = ActiveRecord::Migration.execute(query)
    end

    def database_configuration
      @database_configuration ||= database_connection_file[Rails.env].tap do |config|
        config['username'] = 'app_user'
      end
    end
  end
end
