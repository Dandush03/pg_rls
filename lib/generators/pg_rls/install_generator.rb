# frozen_string_literal: true

require 'rails/generators/base'
require 'securerandom'

module PgRls
  module Generators
    MissingORMError = Class.new(Thor::Error)
    # Installer Generator
    class InstallGenerator < Rails::Generators::Base
      APPLICATION_RECORD_LINE = 'class ApplicationRecord < ActiveRecord::Base'
      APPLICATION_RECORD_PATH = 'app/models/application_record.rb'
      APPLICATION_CONTROLLER_LINE = 'class ApplicationController < ActionController::Base'
      APPLICATION_CONTROLLER_PATH = 'app/controllers/application_controller.rb'
      source_root File.expand_path('../templates', __dir__)

      desc 'Creates a PgRls initializer and copy locale files to your application.'

      def orm_error_message
        <<-ERROR.strip_heredoc
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

        template 'pg_rls.rb.tt', 'config/initializers/pg_rls.rb'

        inject_include_to_application_record
        inject_include_to_application_controller
      end

      def inject_include_to_application_record
        return if aplication_record_already_included?

        gsub_file(APPLICATION_RECORD_PATH, /(#{Regexp.escape(APPLICATION_RECORD_LINE)})/mi) do |match|
          "#{match}\n  include PgRls::SecureConnection\n"
        end
      end

      def inject_include_to_application_controller
        return if aplication_controller_already_included?

        gsub_file(APPLICATION_CONTROLLER_PATH, /(#{Regexp.escape(APPLICATION_CONTROLLER_LINE)})/mi) do |match|
          "#{match}\n  include PgRls::MultiTenancy\n"
        end
      end

      def aplication_controller_already_included?
        File.readlines(APPLICATION_CONTROLLER_PATH).grep(/include PgRls::MultiTenancy/).any?
      end

      def aplication_record_already_included?
        File.readlines(APPLICATION_RECORD_PATH).grep(/include PgRls::SecureConnection/).any?
      end

      def initialize_error_text
        <<-ERROR.strip_heredoc
        ERROR
      end

      def show_readme
        readme 'README' if behavior == :invoke
      end

      hook_for :orm, required: true
    end
  end
end
