class BackportPgRlsToUserActivities < ActiveRecord::Migration[8.1]
  def up
    # Suggested Code:
    # PgRls.on_each_tenant do |tenant|
    #   UserActivity.where(identifier_reference_for_tenant: tenant.id)
    #      .in_batches.update_all(tenant_id: tenant.tenant_id)
    # end
  end

  def down
    # Suggested Code:
    # raise ActiveRecord::IrreversibleMigration, 'This migration is irreversible, please restore from backup.'
  end
end
