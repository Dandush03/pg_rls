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
end
