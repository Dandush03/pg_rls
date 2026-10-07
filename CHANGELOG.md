
# [Released]

## [1.0.4] - 2026-10-06

### Fixes

- **After a rollback, `set_rls` could skip a `SET` it needed.** Postgres takes a `SET` back when the transaction it
  ran in rolls back, but the connection kept recording the tenant it had set (`rls_tenant_id`). A connection on
  tenant A that switched to tenant B inside a transaction that then rolled back was on A again while recording B, so
  the next `set_rls` to B was skipped and its queries ran as tenant A (or with no tenant, when none was set before the
  transaction). The connection now forgets its tenant after every statement that may take a `SET` back —
  `ROLLBACK`, `ROLLBACK TO SAVEPOINT`, `ROLLBACK AND CHAIN`, and a `COMMIT` that rolls back instead (the transaction
  had already failed, or the commit itself fails) — even when that statement raises, so the next `set_rls` or
  `Tenant.reset_rls_used_connections` is never skipped: at most one more `SET` after a rollback.
- Unchanged: between the rollback and that next `set_rls` or reset, the session stays on the tenant Postgres restored
  (the one it had before the transaction or savepoint), as it did before.

### Changed

- `rls_tenant_id` is now `String | :unknown | nil`. `RlsTenant::UNKNOWN` (`:unknown`) means a rollback may have put
  the session on any tenant, or none; `nil` still means no tenant. Code reading `rls_tenant_id` directly should treat
  anything but a tenant id as "not known to be on that tenant".

## [1.0.3] - 2026-10-03

### Fixes

- **A connection handed between threads could keep another tenant.** `Tenant#set_rls` skipped the `SET` when the
  thread had set that connection before, going by a per-thread record of the connections it had set. If a connection
  changed threads while that record still listed it — released mid-request, or used across threads, as in system
  tests where the test thread and the server's threads share a pool — the first thread got it back already switched
  by another one and ran as that tenant. Apps that hold the connection for the whole request (pg_rls's own
  `PgRls::Record.connection` calls lease it) were not exposed. The tenant is now recorded on the connection itself
  (`rls_tenant_id`), so the `SET` is skipped only when the connection is already on that tenant: no more statements
  than before, and none skipped that were needed.
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

