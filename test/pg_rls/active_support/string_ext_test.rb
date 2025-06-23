# frozen_string_literal: true

require "test_helper"
module PgRls
  module ActiveSupport
    class StringExtTest < ::ActiveSupport::TestCase
      test "does not modify a string without extra spaces" do
        assert_equal "SELECT * FROM table", "SELECT * FROM table".sanitize_sql
      end

      test "removes trailing spaces" do
        assert_equal "SELECT * FROM table", "SELECT * FROM table ".sanitize_sql
      end

      test "removes leading spaces" do
        assert_equal "SELECT * FROM table", " SELECT * FROM table".sanitize_sql
      end

      test "removes both leading and trailing spaces" do
        assert_equal "SELECT * FROM table", " SELECT * FROM table ".sanitize_sql
      end

      test "removes extra spaces between words" do
        assert_equal "SELECT * FROM table", "SELECT  *  FROM  table".sanitize_sql
      end

      test "removes tabs" do
        assert_equal "SELECT * FROM table", "SELECT\t*\tFROM\ttable".sanitize_sql
      end

      test "removes newlines" do
        assert_equal "SELECT * FROM table", "SELECT\n*\nFROM\ntable".sanitize_sql
      end

      test "removes a combination of newlines, tabs, and spaces" do
        assert_equal "SELECT * FROM table", " SELECT\t*\nFROM  \ttable ".sanitize_sql
      end
    end
  end
end
