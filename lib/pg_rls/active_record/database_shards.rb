# frozen_string_literal: true

module PgRls
  module ActiveRecord
    # Overwrite the configurations method to add the RLS configurations
    module DatabaseShards
      REQUIRED_CONFIGURATION_KEYS = %w[adapter host database username password rls_mode].freeze

      def add_rls_configurations(config, new_config = {})
        current_config = config[Rails.env]

        if rls_shard_config?(current_config)
          add_primary_and_rls_config(current_config, new_config)
        else
          current_config.each do |key, value|
            add_primary_and_rls_config(value, new_config, key)
          end
        end

        { Rails.env => new_config }
      end

      def configurations=(config)
        new_config = add_rls_configurations(config)
        super(new_config)
      end

      private

      def add_primary_and_rls_config(config, new_config, key = "primary")
        new_config[key] = config

        return new_config unless rls_shard_config?(config)

        configuration = adapter_configurations(config, new_config, key)

        if configuration.nil?
          raise ArgumentError,
                "Invalid RLS mode: #{config["rls_mode"]}. valid options are: dual, single, none"
        end

        new_config
      end

      def adapter_configurations(config, new_config, key)
        case config["rls_mode"]
        when "dual"
          new_config["rls_#{key}"] = config.merge(rls_configuration)
        when "single"
          new_config[key] = config.merge(rls_configuration)
        when "none"
          new_config[key] = config
        end
      end

      def rls_configuration
        {
          "username" => PgRls.username.to_s,
          "password" => PgRls.password.to_s,
          "database_tasks" => false,
          "rls" => true
        }
      end

      def rls_shard_config?(config)
        return false unless config.is_a?(Hash)

        REQUIRED_CONFIGURATION_KEYS.all? { |key| config.key?(key) }
      end
    end
  end
end

ActiveRecord::Base.singleton_class.prepend(PgRls::ActiveRecord::DatabaseShards)
