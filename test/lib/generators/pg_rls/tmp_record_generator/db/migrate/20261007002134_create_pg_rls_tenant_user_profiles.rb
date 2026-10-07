class CreatePgRlsTenantUserProfiles < ActiveRecord::Migration[8.1]
  def change
    create_rls_tenant_table :user_profiles do |t|
    end
  end
end
