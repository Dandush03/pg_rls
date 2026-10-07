# frozen_string_literal: true

require "test_helper"
require "generators/pg_rls/install/install_generator"

class InstallGeneratorTest < Rails::Generators::TestCase
  tests PgRls::InstallGenerator
  destination File.expand_path("./tmp_install_generator", __dir__)

  setup do
    # A directory of its own for each parallel worker: tests of one class run in several, and one worker's
    # cleanup took away the files another had just generated (a missing postgres_record.rb on CI).
    self.destination_root = File.expand_path("./tmp_install_generator/#{Process.pid}", __dir__)
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
