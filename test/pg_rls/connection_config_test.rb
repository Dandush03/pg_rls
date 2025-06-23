# frozen_string_literal: true

require "test_helper"

class PgRlsConnectionConfigTest < ActiveSupport::TestCase
  teardown do
    PgRls.reset_config!
  end

  test "look_up_connection_config sets connection config based on default if rls mode is single" do
    db_config = ::ActiveRecord::Base.connection_db_config.configuration_hash.dup
    hash_config = ::ActiveRecord::DatabaseConfigurations::HashConfig.new("test", "primary",
                                                                         db_config.merge(rls_mode: "single"))

    ::ActiveRecord::Base.stub :connection_db_config, hash_config do
      config = PgRls::ConnectionConfig.new
      config.look_up_connection_config
      assert_equal PgRls.connects_to[:database][:writing], :primary
      assert_equal PgRls.connects_to[:database][:reading], :primary
    end
  end

  test "look_up_connection_config sets connection config based on default if rls mode is dual" do
    db_config = ::ActiveRecord::Base.connection_db_config.configuration_hash.dup
    hash_config = ::ActiveRecord::DatabaseConfigurations::HashConfig.new("test", "primary",
                                                                         db_config.merge(rls_mode: "dual"))

    ::ActiveRecord::Base.stub :connection_db_config, hash_config do
      config = PgRls::ConnectionConfig.new
      config.look_up_connection_config
      assert_equal PgRls.connects_to[:shards][:rls][:writing], :rls_primary
      assert_equal PgRls.connects_to[:shards][:rls][:reading], :rls_primary
      assert_equal PgRls.connects_to[:shards][:admin][:writing], :primary
      assert_equal PgRls.connects_to[:shards][:admin][:reading], :primary
    end
  end

  test "look_up_connection_config sets connection config based on default if rls mode is none" do
    db_config = ::ActiveRecord::Base.connection_db_config.configuration_hash.dup
    hash_config = ::ActiveRecord::DatabaseConfigurations::HashConfig.new("test", "primary",
                                                                         db_config.merge(rls_mode: "none"))

    ::ActiveRecord::Base.stub :connection_db_config, hash_config do
      config = PgRls::ConnectionConfig.new
      config.look_up_connection_config
      assert_equal PgRls.connects_to[:database][:writing], :primary
      assert_equal PgRls.connects_to[:database][:reading], :primary
    end
  end

  test "invalid_connection_config raises InvalidConnectionConfig error" do
    config = PgRls::ConnectionConfig.new
    assert_raises(PgRls::Error::InvalidConnectionConfig) do
      config.invalid_connection_config
    end
  end

  test "connection_config? returns true if connects_to has database key" do
    PgRls.stub :connects_to, { database: { writing: :default, reading: :default } } do
      config = PgRls::ConnectionConfig.new
      assert config.connection_config?
    end
  end

  test "connection_config? returns false if connects_to is nil or missing database key" do
    PgRls.stub :connects_to, nil do
      config = PgRls::ConnectionConfig.new
      refute config.connection_config?
    end

    PgRls.stub :connects_to, { some_other_key: :value } do
      config = PgRls::ConnectionConfig.new
      refute config.connection_config?
    end
  end
end
