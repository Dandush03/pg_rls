# frozen_string_literal: true

require 'rails/generators/named_base'
require 'rails/generators/active_model'
require 'rails/generators/active_record/migration'
require 'active_record'

module PgRls
  module Generators # :nodoc:
    class PgRlsGenerator < Rails::Generators::NamedBase # :nodoc:
      include PgRls::Generators::Migration

      # Set the current directory as base for the inherited generators.
      def self.base_root
        __dir__
      end
    end
  end
end
