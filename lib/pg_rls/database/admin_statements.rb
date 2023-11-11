# frozen_string_literal: true

module PgRls
  module Admin
    module ActiveRecord
      module Migrator
        def initialize(*args)
          PgRls.instance_variable_set(:@as_db_admin, true)
          super
        end
      end

      module Tasks
        module DatabaseTasks
          def resolve_configuration(configuration)
            PgRls.instance_variable_set(:@as_db_admin, true) unless PgRls.as_db_admin?
            super
          end

          def migration_class
            PgRls.instance_variable_set(:@as_db_admin, true) unless PgRls.as_db_admin?
            super
          end
        end
      end
    end
  end
end
