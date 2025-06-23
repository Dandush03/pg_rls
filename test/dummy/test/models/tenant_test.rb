# frozen_string_literal: true

require "test_helper"

class TenantTest < ActiveSupport::TestCase
  test "raise error on duplicate tenant_id" do
    tenant_id = SecureRandom.uuid
    tenant = Tenant.new(tenant_id: tenant_id)
    tenant.save
    assert_raises ActiveRecord::RecordNotUnique do
      Tenant.create!(tenant_id: tenant_id)
    end
  end

  test "raise error on update tenant_id" do
    tenant = Tenant.create!(tenant_id: SecureRandom.uuid)
    assert_raises ActiveRecord::StatementInvalid do
      tenant.update!(tenant_id: SecureRandom.uuid)
    end
  end

  test "assign tenant id even if nullify" do
    tenant = Tenant.create!(tenant_id: nil)
    assert_not_nil tenant.tenant_id
  end
end
