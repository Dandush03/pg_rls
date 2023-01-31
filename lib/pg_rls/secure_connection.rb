# frozen_string_literal: true

module PgRls
  # Ensure Connection is with App_use
  module SecureConnection
    def self.establish_secure_connection
      return if secure_connection_established?

      return if PgRls.default_connection?

      PgRls.establish_new_connection
    end

    def self.secure_connection_established?
      PgRls.current_connection_username == PgRls.username
    end

    def self.included(base)
      establish_secure_connection
      base.ignored_columns = %w[tenant_id]
    end
  end
end
