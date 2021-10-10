# frozen_string_literal: true

module PgRls
  # Tenant Controller
  module Tenant
    class << self
      SET_COMPANY_ID_SQL = 'SET rls.tenant_id = %s'
      def switch(resource)
        connection_adapter = PgRls.connection_class
        tenant = tenant_by_subdomain_uuid_or_tenant_id(resource)
        connection_adapter.connection.execute(format(SET_COMPANY_ID_SQL,
                                                     connection_adapter.connection.quote(tenant.tenant_id)))
        "RLS changed to '#{tenant}'"
      rescue StandardError => e
        puts 'connection was not made'
        puts e
      end

      def tenant_by_subdomain_uuid_or_tenant_id(resource)
        Company.find_by_subdomain(resource) || Company.find_by_id(resource) || Company.find_by_tenant_id(resource)
      end
    end
  end
end
