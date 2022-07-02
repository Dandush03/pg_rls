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

    def self.included(_base)
      establish_secure_connection
      # base.class_eval do
      #   after_initialize :establish_secure_connection
      # end
    end
  end
end
