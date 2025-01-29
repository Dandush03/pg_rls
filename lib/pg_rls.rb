# frozen_string_literal: true

require "active_record"
require "forwardable"

require_relative "pg_rls/deprecation"
require_relative "pg_rls/admin"
require_relative "pg_rls/errors"
require_relative "pg_rls/active_record"
require_relative "pg_rls/active_support"
require_relative "pg_rls/version"
require_relative "pg_rls/engine"
require_relative "pg_rls/railtie"
require_relative "pg_rls/connection_config"

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

      connection_config = PgRls::ConnectionConfig.new
      connection_config.look_up_connection_config unless connection_config.connection_config?
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
