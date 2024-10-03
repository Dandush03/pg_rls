
# [Released]

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
