# frozen_string_literal: true

require "test_helper"

class PgRlsTest < ActiveSupport::TestCase
  test "has a version number" do
    assert_not_nil PgRls::VERSION
  end

  test "version is bigger or equal than 1.0.0" do
    assert_operator Gem::Version.new(PgRls::VERSION), :>=, Gem::Version.new("1.0.0")
  end

  test "version is smaller than 1.1.0" do
    assert_operator Gem::Version.new(PgRls::VERSION), :<, Gem::Version.new("1.1.0")
  end
end
