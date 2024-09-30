# frozen_string_literal: true

require "active_record"

# binding.irb
#  db_config_file = File.expand_path("database.yml", __dir__)
#  db_config = YAML.load(ERB.new(File.read(db_config_file)).result, aliases: true)
#  db_config = db_config.deep_symbolize_keys

#  db_task = ::ActiveRecord::Tasks::DatabaseTasks
#  db_task.send(:with_temporary_pool, db_config, clobber: true) do
#    db_task.purge(db_config)
#  rescue ::ActiveRecord::NoDatabaseError
#    db_task.create(db_config)
#  end
#  ::ActiveRecord::Base.establish_connection(db_config)

module PgRls
  class DatabaseConnection
    def initialize
      db_config_file = File.expand_path("database.yml", __dir__)
      config = YAML.safe_load(ERB.new(File.read(db_config_file)).result, aliases: true)

      @db_config = config["test"].deep_symbolize_keys
    end

    attr_reader :db_config

    def self.establish_connection!
      conn = new
      conn.reconstruct_db
      conn.establish_connection
    end

    def establish_connection
      ::ActiveRecord::Base.establish_connection(db_config)
    end

    def reconstruct_db
      db_task = ::ActiveRecord::Tasks::DatabaseTasks
      db_task.migration_class.connection_handler.establish_connection(db_config, clobber: true) do
        db_task.purge(db_config)
      end
    rescue ::ActiveRecord::NoDatabaseError
      db_task.create(db_config)
    end
  end
end
