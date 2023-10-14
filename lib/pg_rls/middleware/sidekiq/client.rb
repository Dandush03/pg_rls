# frozen_string_literal: true

# :nocov:
module PgRls
  module Middleware
    module Sidekiq
      # Set PgRls Policies
      class Client
        def call(_job_class, msg, _queue, _redis_pool)
          load_tenant_attribute!(msg)
          yield
        end

        def load_tenant_attribute!(msg)
          if PgRls.username == PgRls.current_db_username
            tenant = PgRls::Tenant.fetch!
            msg['pg_rls'] = tenant.id
          else
            msg['admin'] = true
          end
        end
      end
    end
  end
end
