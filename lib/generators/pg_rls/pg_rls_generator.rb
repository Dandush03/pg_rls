# frozen_string_literal: true

require_relative File.join(File.dirname(__FILE__), "active_record/active_record_generator")

module PgRls
  module Generators
    # PgRls Generator
    class PgRlsGenerator < ::Rails::Generators::NamedBase
      # override ModelGenerator
      hook_for :orm, required: true
    end
  end
end
