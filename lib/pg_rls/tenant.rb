# frozen_string_literal: true

module PgRls
  # Tenant Controller
  module Tenant
    class << self
      attr_reader :tenant

      def switch(resource)
        switch_tenant!(resource)
      rescue StandardError => e
        puts 'connection was not made'
        puts e
      end

      def switch!(resource)
        switch_tenant!(resource)
      rescue StandardError => e
        puts 'connection was not made'
        raise e
      end

      def fetch
        @fetch ||= PgRls.main_model.find_by_tenant_id(
          PgRls.connection_class.connection.execute(
            "SELECT current_setting('rls.tenant_id')"
          ).getvalue(0, 0)
        )
      rescue ActiveRecord::StatementInvalid
        'no tenant is selected'
      end

      private

      def switch_tenant!(resource)
        @fetch = nil
        connection_adapter = PgRls.connection_class
        find_tenant(resource)

        raise PgRls::Errors::TenantNotFound unless tenant.present?

        connection_adapter.connection.execute(format('SET rls.tenant_id = %s',
                                                     connection_adapter.connection.quote(tenant.tenant_id)))
        "RLS changed to '#{tenant.send(@method)}'"
      end

      def find_tenant(resource)
        @tenant = nil

        PgRls.search_methods.each do |method|
          @method = method
          @tenant ||= PgRls.main_model.send("find_by_#{method}!", resource)
        rescue NoMethodError, ActiveRecord::RecordNotFound => e
          @error = e
        end
      end
    end
  end
end
