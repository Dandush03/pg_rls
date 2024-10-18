# frozen_string_literal: true

require "active_record"
require "forwardable"
require_relative "pg_rls/errors"
require_relative "pg_rls/active_record"
require_relative "pg_rls/active_support"
require_relative "pg_rls/version"
require_relative "pg_rls/engine"
require_relative "pg_rls/railtie"

# Row Level Security for PostgreSQL
module PgRls
  class << self
    extend Forwardable

    def setup
      ::ActiveRecord::Base.ignored_columns += %w[tenant_id]

      yield self

      Rails.application.config.to_prepare do
        PgRls.main_model.ignored_columns = [] if Object.const_defined?(PgRls.class_name)
      end
    end

    def main_model
      class_name.to_s.camelize.constantize
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
end
