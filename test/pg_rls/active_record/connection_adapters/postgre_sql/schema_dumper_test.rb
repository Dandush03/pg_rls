# frozen_string_literal: true

require "test_helper"

module PgRls
  module ActiveRecord
    module ConnectionAdapters
      module PostgreSQL
        class SchemaDumperTest < ::ActiveSupport::TestCase
          setup do
            PgRls.reset_config!
            PgRls.class_name = :Tenant
            PgRls.table_name = :tenants
            connection = ::ActiveRecord::Base.connection
            config = {
              table_name_prefix: ::ActiveRecord::Base.table_name_prefix,
              table_name_suffix: ::ActiveRecord::Base.table_name_suffix
            }
            @stream = StringIO.new
            @schema_dumper = connection.create_schema_dumper(config)
          end

          test "tables method" do
            tmp_stream = StringIO.new
            @schema_dumper.stub :tables, tmp_stream do
              @schema_dumper.tables(@stream)
              assert_equal tmp_stream.string, @stream.string
            end
          end

          test "returns nil for tenant table and store it in a class variable" do
            assert_nil @schema_dumper.instance_variable_get(:@rls_tenant_table)
            @schema_dumper.table("tenants", @stream)
            assert_includes @schema_dumper.instance_variable_get(:@rls_tenant_table), "create_rls_tenant_table"
          end

          test "returns renamed create table method for rls tables" do
            @schema_dumper.table("posts", @stream)
            assert_includes @stream.string, "create_rls_table"
          end

          test "does nothing to regular tables" do
            @schema_dumper.table("comments", @stream)
            assert_includes @stream.string, "create_table"
          end

          test "ensure that rls_tenant_table is always the first table" do
            @schema_dumper.tables(@stream)

            assert_match(/create_rls_tenant_table/, @stream.string.split("\n").first)
          end
        end
      end
    end
  end
end
