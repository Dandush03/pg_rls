# frozen_string_literal: true

require 'rails/generators/base'
require 'securerandom'

module PgRls
  module Generators
    MissingORMError = Class.new(Thor::Error)
    # Installer Generator
    class InstallGenerator < Rails::Generators::Base
      def initialize(*args)
        tenant_model_or_table = args.first
        if tenant_model_or_table.present?
          PgRls.table_name = tenant_model_or_table.first.pluralize
          PgRls.class_name = tenant_model_or_table.first.singularize
        end
        super
      end
      ENVIRONMENT_PATH = 'config/environment.rb'

      APPLICATION_LINE = 'class Application < Rails::Application'
      APPLICATION_PATH = 'config/application.rb'

      APPLICATION_RECORD_LINE = 'class ApplicationRecord < ActiveRecord::Base'
      APPLICATION_RECORD_PATH = 'app/models/application_record.rb'

      APPLICATION_CONTROLLER_LINE = 'class ApplicationController < ActionController::Base'
      APPLICATION_CONTROLLER_PATH = 'app/controllers/application_controller.rb'

      source_root File.expand_path('../templates', __dir__)

      desc 'Creates a PgRls initializer and copy locale files to your application.'

      hook_for :orm, required: true

      def orm_error_message
        <<~ERROR
          An ORM must be set to install PgRls in your application.
          Be sure to have an ORM like Active Record or loaded in your
          app or configure your own at `config/application.rb`.
            config.generators do |g|
              g.orm :your_orm_gem
            end
        ERROR
      end

      def copy_initializer
        raise MissingORMError, orm_error_message unless options[:orm]

        inject_include_to_application
        inject_include_to_application_controller
        template 'pg_rls.rb.tt', 'config/initializers/pg_rls.rb'
      end

      def inject_include_to_environment
        return if environment_already_included?

        prepend_to_file(ENVIRONMENT_PATH, "\nrequire_relative 'initializers/pg_rls'\n")
      end

      def inject_include_to_application
        return if aplication_already_included?

        gsub_file(APPLICATION_PATH, /(#{Regexp.escape(APPLICATION_LINE)})/mio) do |match|
          "#{match}\n  config.active_record.schema_format = :sql\n"
        end
      end

      def inject_include_to_application_controller
        return if aplication_controller_already_included?

        gsub_file(APPLICATION_CONTROLLER_PATH, /(#{Regexp.escape(APPLICATION_CONTROLLER_LINE)})/mio) do |match|
          "#{match}\n  include PgRls::MultiTenancy\n"
        end
      end

      def aplication_controller_already_included?
        File.readlines(APPLICATION_CONTROLLER_PATH).grep(/include PgRls::MultiTenancy/).any?
      end

      def aplication_already_included?
        File.readlines(APPLICATION_PATH).grep(/config.active_record.schema_format = :sql/).any?
      end

      def environment_already_included?
        File.readlines(ENVIRONMENT_PATH).grep(/require_relative 'initializers\/pg_rls'/).any?
      end

      def initialize_error_text
        <<~ERROR
          TO DO
        ERROR
      end

      def show_readme
        readme 'README' if behavior == :invoke
      end
    end
  end
end
