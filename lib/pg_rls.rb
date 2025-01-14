# frozen_string_literal: true

require "active_record"
require "forwardable"

require_relative "pg_rls/deprecation"
require_relative "pg_rls/errors"
require_relative "pg_rls/active_record"
require_relative "pg_rls/active_support"
require_relative "pg_rls/version"
require_relative "pg_rls/engine"
require_relative "pg_rls/railtie"

# Row Level Security for PostgreSQL
module PgRls
  DEFAULT_CONFIG_MAP = {
    "@@search_methods": %i[subdomain tenant_id id],
    "@@table_name": :organizations,
    "@@class_name": :Organization,
    "@@username": :app_user,
    "@@password": :password,
    "@@schema": :public,
    "@@rls_role_group": :rls_group
  }.freeze

  class << self
    extend Forwardable

    def setup
      PgRls.reset_config!
      Rails.application.config.to_prepare do
        PgRls::Record.ignored_columns += %w[tenant_id]
      end

      yield self

      look_up_connection_config unless connection_config?
      freeze_config! unless Rails.env.test?
    end

    def main_model
      class_name.to_s.camelize.constantize
    end

    def reset_config!
      PgRls.class_variables.each do |var|
        PgRls.class_variable_set(var, DEFAULT_CONFIG_MAP[var])
      end
    end

    # :nocov:
    def freeze_config! # rubocop:disable Metrics/MethodLength
      PgRls.singleton_class.class_eval do
        PgRls.class_variables.each do |var_name|
          method_name = var_name.to_s.delete_prefix("@@").to_sym
          setter_method_name = :"#{method_name}="
          const_name = "#{method_name.to_s.upcase}_FROZEN_CONFIGURATION"

          remove_method setter_method_name if method_defined?(setter_method_name)

          PgRls.const_set(const_name, PgRls.class_variable_get(var_name))

          define_method(method_name) do
            PgRls.const_get(const_name)
          end

          PgRls.remove_class_variable(var_name)
        end
      end
    end
    # :nocov:

    def admin_execute(sql = nil)
      PgRls::Record.connected_to(shard: :admin) do
        return yield.presence if block_given?

        PgRls::Record.connection.execute(sql).presence
      end
    end


    def look_up_connection_config
      default_connection_db_config = ::ActiveRecord::Base.connection_db_config
      default_connection_name = default_connection_db_config.name

      config_hash = case default_connection_db_config.configuration_hash[:rls_mode]
                    when "dual"
                      {
                        shards: {
                          rls: { writing: "rls_#{default_connection_name}", reading: "rls_#{default_connection_name}" },
                          admin: { writing: default_connection_name, reading: default_connection_name }
                        }
                      }
                    when "single"
                      { database: { writing: "rls_#{default_connection_name}",
                                    reading: "rls_#{default_connection_name}" } }
                    when "none"
                      { database: { writing: default_connection_name, reading: default_connection_name } }
                    end

      return invalid_connection_config unless config_hash

      PgRls.connects_to = config_hash.deep_transform_values(&:to_sym)
    end

    def connection_config?
      PgRls.connects_to&.key?(:database) || false
    end

    def invalid_connection_config
      raise PgRls::Error::InvalidConnectionConfig,
            "you must edit your database.yml file to include the RLS configuration, " \
            "or set the RLS configuration manually in the PgRls initializer"
    end
  end

  mattr_accessor :search_methods
  @@search_methods = %i[subdomain tenant_id id]

  mattr_accessor :table_name
  @@table_name = :organizations

  mattr_accessor :class_name
  @@class_name = :Organization

  mattr_accessor :username
  @@username = :app_user

  mattr_accessor :password
  @@password = "password"

  mattr_accessor :schema
  @@schema = :public

  mattr_accessor :rls_role_group
  @@rls_role_group = :rls_group

  mattr_accessor :connects_to
  @@connects_to = nil
end
