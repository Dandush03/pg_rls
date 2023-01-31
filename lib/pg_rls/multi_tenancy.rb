# frozen_string_literal: true

module PgRls
  # Ensure Connection is with App_use
  module MultiTenancy
    def self.included(base)
      base.class_eval do
        before_action :switch_tenant!
      end
    end

    private

    def switch_tenant!
      tenant = request.subdomain
      Tenant.switch!(tenant)
      session[:_tenant] = tenant
    rescue PgRls::Errors::TenantNotFound, ActiveRecord::RecordNotFound
      Tenant.switch(session[:_tenant])
    rescue NoMethodError
      session[:_tenant] = nil
      redirect_to '/'
    end

    def switch_tenant_by_resource!(resource = nil)
      Tenant.switch!(resource)
      session[:_tenant] = resource
    rescue PgRls::Errors::TenantNotFound, ActiveRecord::RecordNotFound
      Tenant.switch(session[:_tenant])
    rescue NoMethodError
      session[:tenant] = nil
      redirect_to '/'
    end

    def tenant_match_session_cookies?
      session[:_tenant] == request.subdomain
    end
  end
end
