# frozen_string_literal: true

module PgRls
  module ActiveRecord
    module TestDatabases # :nodoc:
      def create_and_load_schema(i, env_name:)
        super

        PgRls::Record.configurations.configs_for(env_name: env_name, include_hidden: true).each do |db_config|
          next if db_config.name == "primary"

          db_config._database = "#{db_config.database}-#{i}"
        end
      end
    end
  end
end

ActiveRecord::TestDatabases.singleton_class.prepend(PgRls::ActiveRecord::TestDatabases)
