# frozen_string_literal: true

require "test_helper"

class PgRlsAdminTest < ActiveSupport::TestCase
  teardown do
    PgRls.reset_config!
  end

  test "admin_execute configures the connection to use the admin shard" do
    PgRls.stub :connects_to, { shards: { admin: { writing: :admin, reading: :admin } } } do
      result = PgRls::Admin.admin_execute { ::ActiveRecord::Base.connection_db_config.name }
      assert_equal "primary", result
    end
  end

  test "admin_execute can select records from the admin shard" do
    PgRls.stub :connects_to, { shards: { admin: { writing: :admin, reading: :admin } } } do
      result = PgRls::Admin.admin_execute("SELECT 1 AS one")
      assert_equal [{"one" => 1}], result.to_a
    end
  end

  test "admin_execute can update records in the admin shard" do
    PgRls.stub :connects_to, { shards: { admin: { writing: :admin, reading: :admin } } } do
      PgRls::Admin.admin_execute("CREATE TABLE IF NOT EXISTS test_table (id SERIAL PRIMARY KEY, name VARCHAR(255))")
      PgRls::Admin.admin_execute("INSERT INTO test_table (name) VALUES ('initial')")
      PgRls::Admin.admin_execute("UPDATE test_table SET name = 'updated' WHERE name = 'initial'")
      result = PgRls::Admin.admin_execute("SELECT name FROM test_table WHERE name = 'updated'")
      assert_equal [{"name" => "updated"}], result.to_a
    ensure
      PgRls::Admin.admin_execute("DROP TABLE IF EXISTS test_table")
    end
  end
end
