# frozen_string_literal: true

module PgRls
  # Ensure Connection is with App_use
  module MultiTenancy
    def self.included(base)
      base.class_eval do
        before_action :switch_tenant
      end
    end

    private

    def switch_tenant
      Tenant.switch request.subdomain
    rescue NoMethodError
      redirect_to '/'
    end
  end
end
