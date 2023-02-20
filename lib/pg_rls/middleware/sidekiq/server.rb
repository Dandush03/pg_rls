# frozen_string_literal: true

# :nocov:
module PgRls
  module Middleware
    module Sidekiq
      # Set PgRls Policies
      class Server
        def call(_job_instance, msg, _queue, &)
          PgRls::Tenant.with_tenant!(msg['pg_rls'], &)
        end
      end
    end
  end
end
