
# [Released]

## [1.0.3] - 2026-10-03

### Fixes

- **A connection could run as another tenant.** `Tenant#set_rls` skipped the `SET` when the thread had set that
  connection before, going by a per-thread record of the connections it had set. Pooled connections move between
  threads: once another thread had switched the connection to another tenant, the first thread got it back and ran
  as that tenant. Since Rails 7.2 returns the connection to the pool between the queries of a request unless
  something holds it, this could happen within a single request. The tenant is now recorded on the connection
  itself (`rls_tenant_id`), so the `SET` is skipped only when the connection is already on that tenant — no more
  statements than before, and none skipped that were needed.
- A reconnect or a reset (`DISCARD ALL`) drops the session's tenant; the connection now knows it and sets it again.
- `Tenant.reset_rls_used_connections` takes the tenant off the connection it is given, whichever thread set it.

### Removed

- `Tenant.rls_connection_object_cache_by_thread` and its writer, the per-thread record the fix replaces.

## [1.0.1] - 2024-10-10

### Major Changes

- **Switched to Rails native sharding**: We no longer use the `admin_execute` methods for handling admin connections. The database connections are now managed through the Rails native sharding system.
- **New user group `pg_rls`**: All users **must** be assigned to the `pg_rls` group for security and access control purposes. The server will not boot if this is not configured properly.
- **Database configuration changes**: The `database.yml` must be updated to support Rails sharding.
- **Server boot pre-checks**: The server will not boot unless the proper configuration is in place, including shard setup and user group assignment.
- **Performance recommendations**: In production, it is recommended to configure only one user per server, and consider using separate machines for resource-intensive processes.

### Breaking Changes

- `admin_execute` methods have been removed.
- You **must** assign users to the `pg_rls` group.
- `database.yml` requires modification for both development and production environments.

### [0.2.1] - 2024-09-29

- Initial release

