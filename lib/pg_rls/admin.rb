# frozen_string_literal: true

module PgRls
  # The admin module provides the admin_execute method to execute
  # queries on the admin shard.
  module Admin
    def self.admin_execute(sql = nil)
      PgRls::Record.connected_to(shard: :admin) do
        return yield.presence if block_given?

        PgRls::Record.connection.execute(sql).presence
      end
    end
  end
end
