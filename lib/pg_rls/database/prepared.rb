# frozen_string_literal: true

module PgRls
  module Database
    # Prepare database for test unit
    module Prepared
      class << self
        def grant_user_credentials(name: PgRls::SECURE_USERNAME)
          return unless Rails.env.test?

          PgRls.execute <<-SQL
            GRANT USAGE, SELECT
              ON ALL SEQUENCES IN SCHEMA public
                TO #{name};
            GRANT SELECT, INSERT, UPDATE, DELETE
              ON ALL TABLES IN SCHEMA public
                TO #{name};
          SQL
        end
      end
    end
  end
end
