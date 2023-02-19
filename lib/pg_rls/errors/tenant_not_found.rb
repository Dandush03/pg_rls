# frozen_string_literal: true

module PgRls
  module Errors
    # Raise Tenant Not found and ensure that the tenant is resetted
    class TenantNotFound < StandardError
      def initialize(msg = nil)
        reset_tenant_id
        @msg = msg
        super(msg)
      end

      def message
        @msg || "Tenant Doesn't exist"
      end

      def reset_tenant_id
        PgRls.connection_class.connection.execute('RESET rls.tenant_id')
      end
    end
  end
end
