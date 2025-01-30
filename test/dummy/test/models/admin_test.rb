# frozen_string_literal: true

require "test_helper"

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
      assert_equal [{"one" => 1}], result.to_a
    end
  end

  test "execute method can update records in the admin shard" do
    PgRls.stub :connects_to, { shards: { admin: { writing: :admin, reading: :admin } } } do
      PgRls::Admin.execute("CREATE TABLE IF NOT EXISTS test_table (id SERIAL PRIMARY KEY, name VARCHAR(255))")
      PgRls::Admin.execute("INSERT INTO test_table (name) VALUES ('initial')")
      PgRls::Admin.execute("UPDATE test_table SET name = 'updated' WHERE name = 'initial'")
      result = PgRls::Admin.execute("SELECT name FROM test_table WHERE name = 'updated'")
      assert_equal [{"name" => "updated"}], result.to_a
    ensure
      PgRls::Admin.execute("DROP TABLE IF EXISTS test_table")
    end
  end
end
