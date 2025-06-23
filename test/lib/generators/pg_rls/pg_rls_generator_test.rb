# frozen_string_literal: true

require "test_helper"
require "generators/pg_rls/pg_rls_generator"

class PgRlsGeneratorTest < Rails::Generators::TestCase
  tests PgRls::Generators::PgRlsGenerator
  destination File.expand_path("./tmp_pg_rls_generator", __dir__)

  setup do
    prepare_destination
  end

  test "it runs the ActiveRecord generator" do
    assert_nothing_raised do
      run_generator ["User"]
    end
  end

  test "it does not return an output when called twice" do
    run_generator ["User"]
    output = capture(:stdout) { run_generator ["User"] }
    assert_empty output
  end
end
