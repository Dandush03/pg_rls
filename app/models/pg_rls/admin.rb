# frozen_string_literal: true

module PgRls
  # The admin class provides the admin_execute method to execute
  # queries on the admin shard.
  class Admin
    def self.execute(sql = nil)
      PgRls::Record.connected_to(shard: :admin) do
        return yield.presence if block_given?

        PgRls::Record.connection.execute(sql).presence
      end
    end
  end

  # Alias for the Admin.execute method
  def self.admin_execute(sql = nil, &block)
    Deprecation.warn(
      "This method is deprecated and will be removed in future versions. " \
      "please use PgRls::Admin.execute instead."
    )
    Admin.execute(sql, &block)
  end
end
