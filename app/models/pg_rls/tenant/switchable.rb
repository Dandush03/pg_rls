# frozen_string_literal: true

module PgRls
  class Tenant
    # Switchable Module
    module Switchable
      extend ::ActiveSupport::Concern

      included do
        def self.switch(tenant)
          set_rls!(tenant)
        rescue PgRls::Error::TenantNotFound, PgRls::Error::InvalidSearchInput
          nil
        end

        def self.run_within(tenant)
          set_rls!(tenant)

          yield(PgRls::Current.tenant).presence
        ensure
          PgRls::Tenant.reset_rls
        end

        def self.with_tenant!(...)
          PgRls::Deprecation.warn(
            "This method is deprecated and will be removed in future versions. " \
            "please use PgRls::Tenant.run_within instead."
          )
          run_within(...)
        end

        def self.set_rls!(tenant)
          PgRls::Current.tenant = Searchable.by_rls_object(tenant)

          raise PgRls::Error::TenantNotFound, "No tenant found for #{tenant}" unless PgRls::Current.tenant.present?

          PgRls::Current.tenant
        end
        alias_method :set_rls, :set_rls

        def self.reset_rls
          PgRls::Current.reset
        end
      end
    end
  end
end
