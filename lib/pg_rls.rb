# frozen_string_literal: true

require "active_record"
require_relative "pg_rls/errors"
require_relative "pg_rls/active_record"
require_relative "pg_rls/active_support"
require_relative "pg_rls/version"

# Row Level Security for PostgreSQL
module PgRls
  mattr_accessor :schema
  @@schema = "public"

  mattr_accessor :username
  @@username = "app_user"

  mattr_accessor :password
  @@password = "password"
end
