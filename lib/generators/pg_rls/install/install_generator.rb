# frozen_string_literal: true

module PgRls
  # Generator to install the gem
  class InstallGenerator < Rails::Generators::Base
    source_root File.expand_path("../templates", __dir__.to_s)

    attr_reader :attributes

    def initialize(args, *options)
      pg_rls_config(args.first)
      super
    end

    def create_install_config
      template "config/initializers/pg_rls.rb"
    end

    hook_for :orm, required: true

    def show_readme
      readme "USAGE" if invoke?
    end

    private

    def pg_rls_config(tenant_model_or_table)
      raise "Tenant model or table name is required" if tenant_model_or_table.blank?

      PgRls.class_name = tenant_model_or_table.capitalize.singularize.to_sym
      PgRls.table_name = tenant_model_or_table.underscore.pluralize.to_sym
    end

    def invoke?
      behavior == :invoke
    end
  end
end
