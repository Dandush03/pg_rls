# frozen_string_literal: true

module PgRls
  # Ensure Connection is with App_use
  module SecureConnection
    def self.included(base)
      base.class_eval do
        after_initialize :establish_secure_connection
      end
    end

    private

    def establish_secure_connection
      return if secure_connection_established?

      PgRls.establish_new_connection
    end

    def secure_connection_established?
      PgRls.current_connection_username == PgRls::SECURE_USERNAME
    end
  end
end
