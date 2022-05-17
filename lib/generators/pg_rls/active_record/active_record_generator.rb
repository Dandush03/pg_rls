# frozen_string_literal: true

require 'rails/generators/active_record/model/model_generator'
require File.join(File.dirname(__FILE__), '../base')

module PgRls
  module Generators
    # Active Record Generator
    class ActiveRecordGenerator < ::ActiveRecord::Generators::ModelGenerator
      include ::PgRls::Base

      source_root File.expand_path('./templates', __dir__)

      def check_class_collision; end

      def create_migration_file; end

      def migration_exist?
        @migration_exist ||= Dir.glob("#{migration_path}/*create_#{table_name}.rb").present?
      end

      def create_tenant_migration_file
        migration_template(create_migration_template_path,
                           "#{migration_path}/#{create_file_sub_name}_#{table_name}.rb",
                           migration_version: migration_version) if creating?
      end

      def convert_tenant_migration_file
        migration_template(convert_migration_template_path,
                           "#{migration_path}/#{convert_file_sub_name}_#{table_name}.rb",
                           migration_version: migration_version) unless creating?

        migration_template('convert_migration_backport.rb.tt',
                           "#{migration_path}/pg_rls_backport_#{table_name}.rb",
                           migration_version: migration_version) if installation_in_progress?
      end

      def create_model_file
        return if migration_exist?

        generate_abstract_class if database && !parent

        template model_template_path, model_file
      end

      def inject_method_to_model
        return unless installation_in_progress?

        gsub_file(model_file, /Class #{class_name} < #{parent_class_name.classify}/mi) do |match|
          "#{match}\n  def self.current\n    PgRls::Tenant.fetch\n  end\n"
        end
      end

      def model_file
        File.join('app/models', class_path, "#{file_name}.rb")
      end

      def create_migration_template_path
        return 'init_migration.rb.tt' if installation_in_progress?

        'migration.rb.tt'
      end

      def convert_migration_template_path
        return 'init_convert_migration.rb.tt' if installation_in_progress?

        'convert_migration.rb.tt'
      end

      def model_template_path
        return 'init_model.rb.tt' if installation_in_progress?

        'model.rb.tt'
      end

      def create_file_sub_name
        return 'pg_rls_create_tenant' if installation_in_progress?

        'pg_rls_create'
      end

      def convert_file_sub_name
        return 'pg_rls_convert_tenant' if installation_in_progress?

        'pg_rls_convert'
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

      def creating?
        @creating ||= !migration_exist?
      end

      protected

      def migration_action() = 'add'
    end
  end
end
