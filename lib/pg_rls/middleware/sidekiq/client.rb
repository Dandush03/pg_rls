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
          if PgRls.admin_connection?
            msg['admin'] = true
          else
            tenant = PgRls::Tenant.fetch!
            msg['pg_rls'] = tenant.id
          end
        end
      end
    end
  end
end
