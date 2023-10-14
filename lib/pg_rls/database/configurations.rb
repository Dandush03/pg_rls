# frozen_string_literal: true

require 'active_record/database_configurations'

module ActiveRecord
  # ActiveRecord::DatabaseConfigurations
  class DatabaseConfigurations
    class HashConfig
      def initialize(env_name, name, configuration_hash)
        @env_name = env_name
        @name = name
        @configuration_hash = configuration_hash
      end

      def configuration_hash
        return admin_configuration_hash if PgRls.as_db_admin?

        rls_configuration_hash
      end

      def admin_configuration_hash
        @admin_configuration_hash ||= @configuration_hash
      end

      def rls_configuration_hash
        @rls_configuration_hash ||= @configuration_hash.deep_dup.tap do |config|
          config[:username] = PgRls.username
          config[:password] = PgRls.password
        end.freeze
      end
    end
  end
end
