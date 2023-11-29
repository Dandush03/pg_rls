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
          return msg['admin'] = true if PgRls.admin_connection?

          msg['pg_rls'] ||= PgRls::Tenant.fetch&.id
        end
      end
    end
  end
end
