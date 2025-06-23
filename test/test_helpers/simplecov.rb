# frozen_string_literal: true

require "simplecov"

SimpleCov.start "rails" do
  add_filter "/test/"

  add_filter "/vendor/"

  add_group "Database Connection", "lib/pg_rls/active_record/connection_adapters/postgre_sql"
  add_group "Database Schema Statements", "lib/pg_rls/active_record/connection_adapters/schema_statements"
  add_group "Active Support", "lib/pg_rls/active_support"

  minimum_coverage 100

  formatter SimpleCov::Formatter::MultiFormatter.new([
                                                       SimpleCov::Formatter::HTMLFormatter
                                                     ])

  puts "SimpleCov is running"
end
