# frozen_string_literal: true

require "test_helper"

class PgRlsTest < ActiveSupport::TestCase
  class Organization; end # rubocop: disable Lint/EmptyClass

  setup do
    @original_ignored_columns = ActiveRecord::Base.ignored_columns.dup
  end

  teardown do
    PgRls.reset_config!
    ActiveRecord::Base.ignored_columns = @original_ignored_columns
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
      "@@rls_role_group": :rls_group,
      "@@current_attributes": [],
      "@@abstract_base_record_class": "ActiveRecord::Base"
    }
    assert_equal expected_defaults, PgRls::DEFAULT_CONFIG_MAP
  end

  test "setup adds tenant_id to ignored columns" do
    assert_not_includes ActiveRecord::Base.ignored_columns, "tenant_id"

    PgRls.setup { nil }

    assert_includes PgRls::Record.ignored_columns, "tenant_id"
  end

  test "setup executes the block passed to it" do
    block_executed = false

    PgRls.setup do
      block_executed = true
    end

    assert block_executed, "Expected block to be executed during PgRls.setup"
  end

  class ::Organization
    class << self
      attr_accessor :ignored_columns
    end
  end
  test "it sets ignored_columns to an empty array if class_name is defined" do
    PgRls.class_name = "Organization"

    PgRls.setup do |_config|
      PgRls.main_model.ignored_columns = [] if Object.const_defined?(PgRls.class_name)
    end

    assert_equal [], ::Organization.ignored_columns

    Object.send(:remove_const, "Organization")
  end
end
