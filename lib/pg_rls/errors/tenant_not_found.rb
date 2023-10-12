# frozen_string_literal: true

module PgRls
  module Errors
    # Raise Tenant Not found and ensure that the tenant is resetted
    class TenantNotFound < StandardError
      def initialize(msg = nil)
        PgRls::Tenant.reset_rls!
        msg ||= "Tenant Doesn't exist"
        super(msg)
      end
    end
  end
end
