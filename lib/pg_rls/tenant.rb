# frozen_string_literal: true

module PgRls
  # Tenant Controller
  module Tenant
    class << self
      def switch(resource)
        connection_adapter = PgRls.connection_class
        tenant = tenant_by_subdomain_uuid_or_tenant_id(resource)
        connection_adapter.connection.execute(format('SET rls.tenant_id = %s',
                                                     connection_adapter.connection.quote(tenant.tenant_id)))
        "RLS changed to '#{tenant.name}'"
      rescue StandardError => e
        puts 'connection was not made'
        puts e
      end

      def tenant
        PgRls.class_name.to_s.camelize.constantize
      end

      def fetch
        tenant.find_by_tenant_id(
          PgRls.connection_class.connection.execute(
            "SELECT current_setting('rls.tenant_id')"
          ).getvalue(0, 0)
        )
      rescue ActiveRecord::StatementInvalid
        'no tenant is selected'
      end

      def tenant_by_subdomain_uuid_or_tenant_id(resource)
        tenant.find_by_subdomain(resource) || tenant.find_by_id(resource) || tenant.find_by_tenant_id(resource)
      end
    end
  end
end
