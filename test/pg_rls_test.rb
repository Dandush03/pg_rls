# frozen_string_literal: true

require "test_helper"

class PgRlsTest < ActiveSupport::TestCase
  class Organization; end # rubocop: disable Lint/EmptyClass

  teardown do
    PgRls.reset_config!
  end

  test "main_model returns the class name constantize" do
    PgRls.stub :class_name, "PgRlsTest::Organization" do
      assert_equal PgRlsTest::Organization, PgRls.main_model
    end
  end

  test "has a version number" do
    assert_not_nil PgRls::VERSION
  end

  test "version is bigger or equal than 1.0.0" do
    assert_operator Gem::Version.new(PgRls::VERSION), :>=, Gem::Version.new("1.0.0")
  end

  test "version is smaller than 1.1.0" do
    assert_operator Gem::Version.new(PgRls::VERSION), :<, Gem::Version.new("1.1.0")
  end

  test "DEFAULT_CONFIG_MAP has the correct default values" do
    expected_defaults = {
      "@@search_methods": %i[subdomain tenant_id id],
      "@@table_name": :organizations,
      "@@class_name": :Organization,
      "@@username": :app_user,
      "@@password": :password,
      "@@schema": :public,
      "@@rls_role_group": :rls_group
    }
    assert_equal expected_defaults, PgRls::DEFAULT_CONFIG_MAP
  end

  test "look_up_connection_config sets connection config based on default if rls mode not dual" do
    db_config = ::ActiveRecord::Base.connection_db_config.configuration_hash.dup
    hash_config = ::ActiveRecord::DatabaseConfigurations::HashConfig.new("test", "primary",
                                                                         db_config.merge(rls_mode: "single"))

    ::ActiveRecord::Base.stub :connection_db_config, hash_config do
      config = PgRls.look_up_connection_config
      assert_equal config[:database][:writing], :primary
      assert_equal config[:database][:reading], :primary
    end
  end

  test "look_up_connection_config sets connection config based on default if rls mode is dual" do
    db_config = ::ActiveRecord::Base.connection_db_config.configuration_hash.dup
    hash_config = ::ActiveRecord::DatabaseConfigurations::HashConfig.new("test", "primary",
                                                                         db_config.merge(rls_mode: "dual"))

    ::ActiveRecord::Base.stub :connection_db_config, hash_config do
      config = PgRls.look_up_connection_config
      assert_equal config[:database][:writing], :rls_primary
      assert_equal config[:database][:reading], :rls_primary
    end
  end

  test "invalid_connection_config raises InvalidConnectionConfig error" do
    assert_raises(PgRls::Error::InvalidConnectionConfig) do
      PgRls.invalid_connection_config
    end
  end

  test "connection_config? returns true if connects_to has database key" do
    PgRls.stub :connects_to, { database: { writing: :default, reading: :default } } do
      assert PgRls.connection_config?
    end
  end

  test "connection_config? returns false if connects_to is nil or missing database key" do
    PgRls.stub :connects_to, nil do
      refute PgRls.connection_config?
    end

    PgRls.stub :connects_to, { some_other_key: :value } do
      refute PgRls.connection_config?
    end
  end
end
