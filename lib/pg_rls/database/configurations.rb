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
        return @configuration_hash if PgRls.excluded_shards.include?(@name.to_s)

        reset_pg_rls_configuration if db_changed?

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

      def db_changed?
        admin_configuration_hash[:database] != @configuration_hash[:database]
      end

      def reset_pg_rls_configuration
        @rls_configuration_hash = nil
        @admin_configuration_hash = nil
      end
    end
  end
end
