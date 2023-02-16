# frozen_string_literal: true

# :nocov:
module PgRls
  module Middleware
    module Sidekiq
      # Set PgRls Policies
      class Client
        def call(_job_class, msg, _queue, _redis_pool)
          msg['pg_rls'] = PgRls::Tenant.fetch.id
          yield
        end
      end
    end
  end
end
