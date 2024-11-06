# frozen_string_literal: true

require "test_helper"

module PgRls
  class TenantTest < ::ActiveSupport::TestCase
    test "includes Securable module" do
      assert_includes Tenant.included_modules, Tenant::Securable
    end

    test "includes Switchable module" do
      assert_includes Tenant.included_modules, Tenant::Switchable
    end
  end
end
