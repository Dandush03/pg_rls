# frozen_string_literal: true

require "test_helper"
require "generators/pg_rls/install/install_generator"

class InstallGeneratorTest < Rails::Generators::TestCase
  tests PgRls::InstallGenerator
  destination File.expand_path("./tmp_install_generator", __dir__)

  setup do
    prepare_destination
  end

  test "it creates the initializer file" do
    run_generator ["User"]
    assert_file "config/initializers/pg_rls.rb", /PgRls.setup/
  end

  test "it raises an error if no model name is provided" do
    assert_raises RuntimeError do
      run_generator []
    end
  end

  test "it sets the PgRls class_name and table_name based on the provided argument" do
    run_generator ["tenants"]
    assert_equal :Tenant, PgRls.class_name
    assert_equal :tenants, PgRls.table_name
  end
end
