# frozen_string_literal: true

# OVERIDE RAILS TASK
Rake::TaskManager.class_eval do
  def alias_task(fq_name)
    new_name = "#{fq_name}:original"
    @tasks[new_name] = @tasks.delete(fq_name)
  end
end

def alias_task(fq_name)
  Rake.application.alias_task(fq_name)
end

def override_task(*args, &block)
  name, _params, _deps = Rake.application.resolve_args(args.dup)
  fq_name = Rake.application.instance_variable_get(:@scope).to_a.reverse.push(name).join(':')
  alias_task(fq_name)
  Rake::Task.define_task(*args, &block)
end

namespace :db do
  override_task create: :load_config do
    system('AS_DB_ADMIN=true rake db:create:original')
  end

  override_task drop: :load_config do
    system('AS_DB_ADMIN=true rake db:drop:original')
  end

  override_task migrate: :load_config do
    system('AS_DB_ADMIN=true rake db:migrate:original')
  end

  override_task rollback: :load_config do
    system('AS_DB_ADMIN=true rake db:rollback:original')
  end

  override_task prepare: :load_config do
    system('AS_DB_ADMIN=true rake db:prepare:original')
  end

  override_task setup: :load_config do
    system('AS_DB_ADMIN=true rake db:setup:original')
  end

  override_task prepare: :load_config do
    system('AS_DB_ADMIN=true rake db:reset:original')
  end

  override_task purge: :load_config do
    system('AS_DB_ADMIN=true rake db:purge:original')
  end

  override_task abort_if_pending_migrations: :load_config do
    system('AS_DB_ADMIN=true rake db:abort_if_pending_migrations:original')
  end

  override_task seed: :load_config do
    system('AS_DB_ADMIN=true rake db:seed:original')
  end

  namespace :test do
    override_task create: :load_config do
      system('AS_DB_ADMIN=true rake db:test:create:original')
    end

    override_task drop: :load_config do
      system('AS_DB_ADMIN=true rake db:test:drop:original')
    end

    override_task prepare: :load_config do
      system('AS_DB_ADMIN=true rake db:test:prepare:original')
    end

    override_task setup: :load_config do
      system('AS_DB_ADMIN=true rake db:test:setup:original')
    end

    override_task purge: :load_config do
      system('AS_DB_ADMIN=true rake db:test:purge:original')
    end

    override_task load_schema: :load_config do
      system('AS_DB_ADMIN=true rake db:test:load_schema:original')
    end
  end

  namespace :enviroment do
    override_task set: :load_config do
      system('AS_DB_ADMIN=true rake db:enviroment:set:original')
    end
  end

  namespace :schema do
    override_task load: :load_config do
      system('AS_DB_ADMIN=true rake db:schema:load:original')
      PgRls.admin_execute do
        PgRls.execute <<-SQL
          DROP ROLE IF EXISTS #{PgRls::SECURE_USERNAME};
          CREATE USER #{PgRls::SECURE_USERNAME} WITH PASSWORD '#{PgRls.database_configuration['password']}';
          GRANT ALL PRIVILEGES ON TABLE schema_migrations TO #{PgRls::SECURE_USERNAME};
          GRANT USAGE ON SCHEMA public TO #{PgRls::SECURE_USERNAME};
          ALTER DEFAULT PRIVILEGES IN SCHEMA public
            GRANT SELECT, INSERT, UPDATE, DELETE
            ON TABLES TO #{PgRls::SECURE_USERNAME};
          GRANT SELECT, INSERT, UPDATE, DELETE
            ON ALL TABLES IN SCHEMA public
            TO #{PgRls::SECURE_USERNAME};
          GRANT USAGE, SELECT
            ON ALL SEQUENCES IN SCHEMA public
            TO #{PgRls::SECURE_USERNAME};
        SQL
      end
    end
  end
end
