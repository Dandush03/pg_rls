# frozen_string_literal: true

module PgRls
  class Tenant
    # Switchable Module
    module Switchable
      extend ::ActiveSupport::Concern

      included do
        def self.switch(tenant)
          switch!(tenant)
        rescue PgRls::Error::TenantNotFound, PgRls::Error::InvalidSearchInput
          nil
        end

        def self.switch!(tenant)
          PgRls::Current.tenant = Searchable.by_rls_object(tenant)

          raise PgRls::Error::TenantNotFound, "No tenant found for #{tenant}" unless PgRls::Current.tenant.present?

          PgRls::Current.tenant.set_rls
        end

        def self.run_within(tenant)
          switch!(tenant)

          yield(PgRls::Current.tenant).presence
        ensure
          PgRls::Current.tenant.reset_rls
        end

        def self.with_tenant!(...)
          PgRls::Deprecation.warn(
            "This method is deprecated and will be removed in future versions. " \
            "please use PgRls::Tenant.run_within instead."
          )
          run_within(...)
        end
      end
    end
  end
end
