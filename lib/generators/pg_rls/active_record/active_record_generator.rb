# frozen_string_literal: true

require 'rails/generators/active_record/model/model_generator'
require File.join(File.dirname(__FILE__), '../base')

module PgRls
  module Generators
    # Active Record Generator
    class ActiveRecordGenerator < ::ActiveRecord::Generators::ModelGenerator
      include ::PgRls::Base

      source_root File.expand_path('./templates', __dir__)

      hook_for :test_framework

      def create_migration_file
        migration_template template_path, "#{migration_path}/#{file_sub_name}_#{table_name}.rb",
                           migration_version: migration_version
      end

      def template_path
        return 'init_migration.rb.tt' if installation_in_progress?

        'migration.rb.tt'
      end

      def file_sub_name
        return 'pg_rls_tenant_create' if installation_in_progress?

        'pg_rls_create'
      end

      def installation_in_progress?
        shell.base.class.name.include?('Install')
      end

      def migration_version
        "[#{Rails::VERSION::MAJOR}.#{Rails::VERSION::MINOR}]"
      end

      def migration_path
        db_migrate_path
      end

      protected

      def migration_action() = 'add'
    end
  end
end
