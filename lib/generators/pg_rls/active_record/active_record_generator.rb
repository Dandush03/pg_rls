# frozen_string_literal: true

require "rails/generators/active_record/model/model_generator"

module PgRls
  module Generators
    # Active Record Generator
    class ActiveRecordGenerator < ::ActiveRecord::Generators::ModelGenerator
      source_root File.expand_path("../templates", __dir__.to_s)

      class_option :parent, type: :string, default: "ApplicationRecord",
                            desc: "The parent class for the generated model"

      class_option :rls_parent, type: :string, default: "PgRls::Record",
                                desc: "The parent class for the rls generated model"

      # Need to override so it will not check for class collision
      def check_class_collision
        super
        @class_coalescing = false
      rescue Rails::Generators::Error
        @class_coalescing = true
      end

      def create_model_file
        return if class_coalescing?

        generate_abstract_class if database && !custom_parent?
        template("app/models/model.rb", model_path, parent_class_name: parent_class_name)
      end

      def upgrade_model_file
        return unless class_coalescing? && model_file_exists?

        gsub_file(model_path, /< ApplicationRecord/, "< #{parent_class_name}")
      end

      def create_migration_file
        return if skip_migration_creation? || class_coalescing?

        clean_indexes_attributes!
        migration_template "db/migrate/create_#{migration_template_prefix}_table.rb",
                           "db/migrate/create_#{migration_template_prefix}_#{table_name}.rb"
      end

      def upgrade_migration_file
        return if skip_migration_creation? || !class_coalescing?

        migration_template "db/migrate/convert_to_#{migration_template_prefix}_table.rb",
                           "db/migrate/convert_to_#{migration_template_prefix}_#{table_name}.rb"
      end

      def backport_migration_file
        return if skip_migration_creation? || installing? || !class_coalescing?

        migration_template "db/migrate/backport_pg_rls_table.rb",
                           "db/migrate/backport_pg_rls_to_#{table_name}.rb"
      end

      private

      def installing?
        Kernel.const_defined?("PgRls::InstallGenerator")
      end

      def parent_class_name
        return options[:parent] if options[:parent].present?
        return rls_parent unless installing?

        super
      end

      def rls_parent
        options[:rls_parent]
      end

      def migration_template_prefix
        installing? ? "pg_rls_tenant" : "pg_rls"
      end

      def generate_abstract_class
        return if File.exist?(generate_abstract_class_path)

        template "app/models/abstract_base_class.rb", generate_abstract_class_path
      end

      def model_path
        File.join("app/models", class_path, "#{file_name}.rb")
      end

      def generate_abstract_class_path
        File.join("app/models", "#{database.underscore}_record.rb")
      end

      def class_coalescing?
        @class_coalescing
      end

      def clean_indexes_attributes!
        return unless options[:indexes] == false

        attributes.each do |a|
          a.attr_options.delete(:index) if a.reference? && !a.has_index?
        end
      end

      def model_file_exists?
        File.exist?(File.join(destination_root, model_path))
      end
    end
  end
end
