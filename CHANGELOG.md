
# [Released]

## [1.0.4] - 2026-10-06

### Fixes

- **A rolled-back transaction could leave a connection on another tenant than pg_rls recorded.** Postgres undoes a
  `SET` made inside a transaction or a savepoint that rolls back, but `rls_tenant_id` kept the tenant set inside it.
  The next switch to that tenant skipped its `SET` and ran on whatever tenant the session had before the
  transaction, and a reset after it was skipped as if the connection had none. Only a tenant switched without being
  restored inside a transaction that then rolls back is affected (`run_within` restores its own before the
  rollback); a transactional test switching the tenant is exactly that, and a concurrency test then read nothing.
  After anything that rolls back — `ROLLBACK`, `ROLLBACK TO SAVEPOINT`, `ROLLBACK AND CHAIN` (Rails restarting a
  transaction that had not written), and a `COMMIT` of a transaction that had already failed, which Postgres turns
  into a rollback — the connection's tenant is now unknown (`RlsTenant::UNKNOWN`): the next switch sets it, and a
  reset resets it. The cost is one `SET` after a rollback; whether a transaction had failed is asked of the client
  library, with no round trip. The rollback cases and the CI matrix below come from #42 (@david-pulgarin-skydropx).
- **Parallel tests on Rails 8.1.** `PgRls::ActiveRecord::TestDatabases` named every worker's RLS databases after it,
  but Rails 8.1 names hidden configurations itself, so they were named twice (`test_db_1-1`) and no worker came up.
  It now names only the ones Rails left alone, on every version.

### Compatibility

- The suite runs in CI on Rails 7.2, 8.0 and 8.1 — every version the gemspec allows — with parallel workers
  (`gemfiles/`, not packaged). On Rails 8.1 the suite's coverage report is written again: the workers' teardown
  had stopped SimpleCov in the main process too.

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

