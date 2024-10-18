# frozen_string_literal: true

module PgRls
  module ActiveRecord
    module Migration
      # ActiveRecord Migration Command Recorder Extension
      module CommandRecorder
        REVERSIBLE_AND_IRREVERSIBLE_METHODS = %i[
          create_rls_tenant_table convert_to_rls_tenant_table drop_rls_tenant_table
          create_rls_table convert_to_rls_table drop_rls_table
        ].freeze

        def self.included(base)
          REVERSIBLE_AND_IRREVERSIBLE_METHODS.each do |method|
            base.class_eval <<-RUBY, __FILE__, __LINE__ + 1
              def #{method}(*args, &block)          # def create_table(*args, &block)
                record(:"#{method}", args, &block)  #   record(:create_table, args, &block)
              end                                   # end
            RUBY
            base.send(:ruby2_keywords, method)
          end
        end
      end
    end
  end
end

ActiveRecord::Migration::CommandRecorder.include(PgRls::ActiveRecord::Migration::CommandRecorder)
