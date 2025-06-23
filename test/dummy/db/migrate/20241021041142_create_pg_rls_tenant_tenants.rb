# frozen_string_literal: true

class CreatePgRlsTenantTenants < ActiveRecord::Migration[7.2]
  def change
    create_rls_tenant_table :tenants do |t|
      t.string :name
      t.string :subdomain

      t.timestamps
    end
  end
end
