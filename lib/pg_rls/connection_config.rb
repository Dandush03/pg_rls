# frozen_string_literal: true

module PgRls
  # The ConnectionConfig class provides methods to configure and manage
  # the connection settings for Row Level Security (RLS) in PostgreSQL.
  # It includes methods to look up and validate the connection configuration,
  # as well as helper methods to build the configuration hash based on different modes.
  class ConnectionConfig
    def initialize(db_config = ::ActiveRecord::Base.connection_db_config)
      @db_config = db_config
      @connection_name = db_config.name
    end

    def look_up_connection_config
      config_hash = build_config_hash(@db_config, @connection_name)

      return invalid_connection_config unless config_hash

      PgRls.connects_to = config_hash.deep_transform_values(&:to_sym)
    end

    def connection_config?
      PgRls.connects_to&.key?(:database) || false
    end

    def invalid_connection_config
      raise PgRls::Error::InvalidConnectionConfig,
            "you must edit your database.yml file to include the RLS configuration, " \
            "or set the RLS configuration manually in the PgRls initializer"
    end

    private

    def build_config_hash(db_config, connection_name)
      case db_config.configuration_hash[:rls_mode]
      when "dual"
        build_dual_mode_config(connection_name)
      when "single"
        build_single_mode_config(connection_name)
      when "none"
        build_none_mode_config(connection_name)
      end
    end

    def build_dual_mode_config(connection_name)
      {
        shards: {
          rls: { writing: "rls_#{connection_name}", reading: "rls_#{connection_name}" },
          admin: { writing: connection_name, reading: connection_name }
        }
      }
    end

    def build_single_mode_config(connection_name)
      {
        database: {
          writing: "rls_#{connection_name}",
          reading: "rls_#{connection_name}"
        }
      }
    end

    def build_none_mode_config(connection_name)
      {
        database: {
          writing: connection_name,
          reading: connection_name
        }
      }
    end
  end
end
