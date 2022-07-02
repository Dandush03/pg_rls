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
  include PgRls::Schema::UpStatements

  def admin_connection
    PgRls.as_db_admin = true
    PgRls.establish_new_connection

    yield
  ensure
    PgRls.as_db_admin = false
    ActiveRecord::Base.connection.disconnect!
    PgRls.establish_new_connection
  end

  override_task grant_usage: :load_config do
    admin_connection do
      create_rls_user
    end
  end

  override_task create: :load_config do
    admin_connection do
      Rake::Task['db:create:original'].invoke
    end
  end

  override_task drop: :load_config do
    admin_connection do
      Rake::Task['db:drop:original'].invoke
    end
  end

  override_task migrate: :load_config do
    admin_connection do
      Rake::Task['db:migrate:original'].invoke
    end
  end

  override_task rollback: :load_config do
    admin_connection do
      Rake::Task['db:rollback:original'].invoke
    end
  end

  override_task prepare: :load_config do
    admin_connection do
      Rake::Task['db:prepare:original'].invoke
    end
  end

  override_task setup: :load_config do
    admin_connection do
      Rake::Task['db:setup:original'].invoke
    end
  end

  override_task prepare: :load_config do
    admin_connection do
      Rake::Task['db:reset:original'].invoke
    end
  end

  override_task purge: :load_config do
    admin_connection do
      Rake::Task['db:purge:original'].invoke
    end
  end

  override_task abort_if_pending_migrations: :load_config do
    admin_connection do
      Rake::Task['db:abort_if_pending_migrations:original'].invoke
    end
  end

  namespace :test do
    def admin_connection_test_db
      Rails.env = 'test'
      PgRls.as_db_admin = true
      PgRls.establish_new_connection

      yield
    ensure
      PgRls.as_db_admin = false
      ActiveRecord::Base.connection.disconnect!
      PgRls.establish_new_connection
    end

    override_task grant_usage: :load_config do
      admin_connection_test_db do
        create_rls_user
      end
    end

    override_task create: :load_config do
      admin_connection_test_db do
        Rake::Task['db:test:create:original'].invoke
      end
    end

    override_task drop: :load_config do
      admin_connection_test_db do
        Rake::Task['db:test:drop:original'].invoke
      end
    end

    override_task prepare: :load_config do
      admin_connection_test_db do
        Rake::Task['db:test:prepare:original'].invoke
      end
    end

    override_task setup: :load_config do
      admin_connection_test_db do
        Rake::Task['db:test:setup:original'].invoke
      end
    end

    override_task purge: :load_config do
      admin_connection_test_db do
        Rake::Task['db:test:purge:original'].invoke
      end
    end

    override_task load_schema: :load_config do
      admin_connection_test_db do
        Rake::Task['db:test:load_schema:original'].invoke
      end
    end
  end

  namespace :enviroment do
    override_task set: :load_config do
      admin_connection do
        Rake::Task['db:enviroment:set:original'].invoke
      end
    end
  end

  namespace :schema do
    override_task load: :load_config do
      admin_connection do
        Rake::Task['db:schema:load:original'].invoke
        Rake::Task['db:grant_usage'].invoke
        Rake::Task['db:test:grant_usage'].invoke
      end
    end

    override_task dump: :load_config do
      admin_connection do
        Rake::Task['db:schema:dump:original'].invoke
      end
    end
  end
end
