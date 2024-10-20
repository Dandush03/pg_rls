# frozen_string_literal: true

module PgRls
  module ActiveRecord
    module ConnectionAdapters
      module PostgreSQL
        # This module contains the logic to validate user privileges
        module SqlHelperMethod
          private

          def execute_sql!(statement)
            ::ActiveRecord::Base.transaction(requires_new: true) do
              execute(statement.sanitize_sql)
            rescue StandardError => e
              raise e unless rescue_sql_error?(e)

              ::ActiveRecord::Base.connection.rollback_db_transaction
              retry
            end
          end

          def rescue_sql_error?(error)
            error.message.include?("PG::InFailedSqlTransaction") || error.message.include?("PG::TRDeadlockDetected")
          end
        end
      end
    end
  end
end
