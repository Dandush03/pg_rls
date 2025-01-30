# frozen_string_literal: true

require "test_helper"
require_relative "../../../lib/pg_rls/deprecation"
require_relative "../../../app/models/pg_rls/admin"

class PgRlsAdminTest < ActiveSupport::TestCase
  teardown do
    PgRls.reset_config!
  end

  test "execute method configures the connection to use the admin shard" do
    PgRls.stub :connects_to, { shards: { admin: { writing: :admin, reading: :admin } } } do
      result = PgRls::Admin.execute { ::ActiveRecord::Base.connection_db_config.name }
      assert_equal "primary", result
    end
  end

  test "execute method can select records from the admin shard" do
    PgRls.stub :connects_to, { shards: { admin: { writing: :admin, reading: :admin } } } do
      result = PgRls::Admin.execute("SELECT 1 AS one")
      assert_equal [{ "one" => 1 }], result.to_a
    end
  end

  test "execute method can update records in the admin shard" do
    PgRls.stub :connects_to, { shards: { admin: { writing: :admin, reading: :admin } } } do
      PgRls::Admin.execute("CREATE TABLE IF NOT EXISTS test_table (id SERIAL PRIMARY KEY, name VARCHAR(255))")
      PgRls::Admin.execute("INSERT INTO test_table (name) VALUES ('initial')")
      PgRls::Admin.execute("UPDATE test_table SET name = 'updated' WHERE name = 'initial'")
      result = PgRls::Admin.execute("SELECT name FROM test_table WHERE name = 'updated'")
      assert_equal [{ "name" => "updated" }], result.to_a
    ensure
      PgRls::Admin.execute("DROP TABLE IF EXISTS test_table")
    end
  end

  test "admin_execute method delegates to Admin.execute" do
    PgRls.stub :connects_to, { shards: { admin: { writing: :admin, reading: :admin } } } do
      result = PgRls.admin_execute("SELECT 1 AS one")
      assert_equal [{ "one" => 1 }], result.to_a
    end
  end

  test "admin_execute method issues a deprecation warning" do
    PgRls.stub :connects_to, { shards: { admin: { writing: :admin, reading: :admin } } } do
      # rubocop:disable Layout/LineLength
      output_regex = /DEPRECATION WARNING: This method is deprecated and will be removed in future versions. please use PgRls::Admin.execute instead./
      # rubocop:enable Layout/LineLength
      assert_output(nil, output_regex) do
        PgRls.admin_execute("SELECT 1 AS one")
      end
    end
  end
end
