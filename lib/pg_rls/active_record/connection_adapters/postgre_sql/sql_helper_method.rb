# frozen_string_literal: true

module PgRls
  module ActiveRecord
    module ConnectionAdapters
      module PostgreSQL
        # This module contains the logic to validate user privileges
        module SqlHelperMethod
          private

          def execute_sql!(statement)
            transaction(requires_new: true) do
              execute(statement.sanitize_sql)
            end
          end
        end
      end
    end
  end
end
