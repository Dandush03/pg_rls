# frozen_string_literal: true

module PgRls
  # Ensure Connection is with App_use
  module MultiTenancy
    def self.included(base)
      base.class_eval do
        around_action :switch_tenant!

        def current_tenant
          @current_tenant ||= request.subdomain
        end
        helper_method :current_tenant
      end
    end

    private

    def switch_tenant!
      fetched_tenant = session[:_tenant] || current_tenant
      return yield if PgRls::Tenant.fetch.present?

      Tenant.with_tenant!(fetched_tenant) do |tenant|
        session[:_tenant] = tenant
        yield(tenant)
      end
    rescue NoMethodError
      session[:_tenant] = nil
      raise PgRls::Errors::TenantNotFound, 'No tenant was found'
    end
  end
end
