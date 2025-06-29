# frozen_string_literal: true

require "test_helper"

module PgRls
  class RecordTest < ::ActiveSupport::TestCase
    test "Record is an abstract class" do
      assert Record.abstract_class?, "BaseModel should be an abstract class"
    end

    test "Connects to RLS connection" do
      assert_equal "rls_primary", Record.connection_db_config.name
    end

    test "Record inherits from configured base class" do
      expected_class = PgRls.abstract_base_record_class.constantize
      assert_equal expected_class, Record.superclass
    end
  end
end
