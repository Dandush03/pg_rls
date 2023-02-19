# frozen_string_literal: true

module PgRls
  # Tenant Controller
  module Tenant
    class << self
      attr_reader :tenant

      def switch(resource)
        tenant = switch_tenant!(resource)

        "RLS changed to '#{tenant.id}'"
      rescue StandardError => e
        Rails.logger.info('connection was not made')
        Rails.logger.info(e)
        nil
      end

      def switch!(resource)
        tenant = switch_tenant!(resource)

        "RLS changed to '#{tenant.id}'"
      rescue StandardError => e
        Rails.logger.info('connection was not made')
        raise e
      end

      def find_each(&)
        PgRls.main_model.find_each do |tenant|
          with_tenant!(tenant, &)
        end
      end

      def with_tenant!(resource, &block)
        tenant = switch_tenant!(resource)

        block.call(tenant) if block_given?
      ensure
        reset_rls! unless PgRls.test_inline_tenant == true
      end

      def fetch
        fetch!
      rescue ActiveRecord::StatementInvalid, ActiveRecord::RecordNotFound
        nil
      end

      def fetch!
        @tenant ||= PgRls.main_model.find_by!(
          tenant_id: PgRls.connection_class.connection.execute(
            "SELECT current_setting('rls.tenant_id')"
          ).getvalue(0, 0)
        )
      end

      def find_main_model
        PgRls.main_model.ignored_columns = []
        PgRls.main_model.find_by!(
          tenant_id: PgRls.connection_class.connection.execute(
            "SELECT current_setting('rls.tenant_id')"
          ).getvalue(0, 0)
        )
      end

      def reset_rls!
        @tenant = nil
        PgRls.connection_class.connection.execute('RESET rls.tenant_id')
      end

      private

      def switch_tenant!(resource)
        PgRls.main_model.ignored_columns = []

        connection_adapter = PgRls.connection_class
        find_tenant(resource)

        raise PgRls::Errors::TenantNotFound if tenant.blank?

        connection_adapter.connection.transaction do
          connection_adapter.connection.execute(format('SET rls.tenant_id = %s',
                                                       connection_adapter.connection.quote(tenant.tenant_id)))
        end

        tenant
      end

      def find_tenant(resource)
        reset_rls!

        PgRls.search_methods.each do |method|
          break if @tenant.present?

          @method = method
          @tenant = find_tenant_by_method(resource, method)
        end

        raise PgRls::Errors::TenantNotFound if tenant.nil?
      end

      def find_tenant_by_method(resource, method)
        look_up_value = resource.is_a?(PgRls.main_model) ? resource.send(method) : resource
        PgRls.main_model.send("find_by_#{method}!", look_up_value)
      rescue ActiveRecord::RecordNotFound
        nil
      end
    end
  end
end
