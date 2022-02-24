# frozen_string_literal: true

module PgRls
  # Tenant Controller
  module Tenant
    class << self
      def switch(resource)
        @fetch = nil
        connection_adapter = PgRls.connection_class
        find_tenant(resource)
        connection_adapter.connection.execute(format('SET rls.tenant_id = %s',
                                                     connection_adapter.connection.quote(tenant.tenant_id)))
        "RLS changed to '#{tenant.send(@method)}'"
      rescue StandardError => e
        puts 'connection was not made'
        puts @error || e
      end

      attr_reader :tenant

      def fetch
        @fetch ||= PgRls.main_model.find_by_tenant_id(
          PgRls.connection_class.connection.execute(
            "SELECT current_setting('rls.tenant_id')"
          ).getvalue(0, 0)
        )
      rescue ActiveRecord::StatementInvalid
        'no tenant is selected'
      end

      def find_tenant(resource)
        @tenant = nil

        PgRls.search_methods.each do |method|
          @method = method
          @tenant ||= PgRls.main_model.send("find_by_#{method}!", resource)
        rescue NoMethodError => e
          @error = e
        rescue ActiveRecord::RecordNotFound
          raise PgRls::Errors::TenantNotFound
        end
      end
    end
  end
end
