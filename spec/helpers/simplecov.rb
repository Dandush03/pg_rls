# frozen_string_literal: true

require "simplecov"

SimpleCov.configure do
  add_filter "/spec/"
  add_filter "/vendor/"

  add_group "Database Connection", "lib/pg_rls/active_record/connection_adapters/postgre_sql"
  add_group "Database Schema Statements", "lib/pg_rls/active_record/connection_adapters/schema_statements"
  add_group "Active Support", "lib/pg_rls/active_support"

  coverage_dir "coverage"

  minimum_coverage 100
  formatter SimpleCov::Formatter::MultiFormatter.new([
                                                       SimpleCov::Formatter::HTMLFormatter
                                                     ])
end

SimpleCov.start
