# frozen_string_literal: true

# OVERIDE RAILS TASK
Rake::TaskManager.class_eval do
  def alias_task(fq_name)
    new_name = "#{fq_name}:original"
    @tasks[new_name] = @tasks.delete(fq_name) unless @tasks[fq_name].nil?
  end
end

def alias_task(fq_name)
  Rake.application.alias_task(fq_name)
end

def override_task(*args, &)
  name, _params, _deps = Rake.application.resolve_args(args.dup)
  fq_name = Rake.application.instance_variable_get(:@scope).to_a.reverse.push(name).join(':')
  alias_task(fq_name)
  Rake::Task.define_task(*args, &)
end

namespace :db do
  include PgRls::Schema::UpStatements

  override_task :load_config do
    PgRls.instance_variable_set(:@as_db_admin, true)
    Rake::Task['db:load_config:original'].invoke
  end

  override_task grant_usage: :load_config do
    create_rls_user
  end

  namespace :test do
    override_task grant_usage: :load_config do
      PgRls.instance_variable_set(:@as_db_admin, true)
      create_rls_user
    end
  end
end
