# frozen_string_literal: true

module PgRls
  module ActiveRecord
    module TestDatabases # :nodoc:
      # Each parallel worker gets databases of its own. Rails names them, but before 8.1 only the configurations it
      # does not hide, and pg_rls's are hidden: those are named here — and only those Rails left alone, because from
      # 8.1 on it names hidden ones too (`<database>_<i>`), and naming them again pointed every worker at a database
      # that does not exist.
      def create_and_load_schema(i, env_name:)
        configs = PgRls::Record.configurations.configs_for(env_name: env_name, include_hidden: true)
                                              .reject { |db_config| db_config.name == "primary" }
        named = configs.to_h { |db_config| [db_config, db_config.database] }

        super

        configs.each do |db_config|
          db_config._database = "#{db_config.database}-#{i}" if db_config.database == named[db_config]
        end
      end
    end
  end
end

ActiveRecord::TestDatabases.singleton_class.prepend(PgRls::ActiveRecord::TestDatabases)
