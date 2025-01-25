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
end
