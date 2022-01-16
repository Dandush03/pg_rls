# frozen_string_literal: true

require_relative '../pg_rls'
require 'rails'

module PgRls
  # Extend Rails Railties
  class Railtie < Rails::Railtie
    railtie_name :my_gem

    rake_tasks do
      path = File.dirname(__FILE__)
      Dir.glob("#{path}/database/tasks/**/*.rake").each { |f| load f }
    end
  end
end
