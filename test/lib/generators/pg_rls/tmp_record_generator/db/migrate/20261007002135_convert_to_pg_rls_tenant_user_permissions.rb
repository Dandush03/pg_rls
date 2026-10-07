class ConvertToPgRlsTenantUserPermissions < ActiveRecord::Migration[8.1]
  def change
    convert_to_rls_tenant_table :user_permissions
  end
end
