# frozen_string_literal: true

module PgRls
  # Tenant Controller
  module Tenant
    class << self
      def switch(resource)
        switch!(resource)
      rescue PgRls::Errors::TenantNotFound
        nil
      end

      def switch!(resource)
        tenant = switch_tenant!(resource)

        "RLS changed to '#{tenant.id}'"
      rescue StandardError
        Rails.logger.info('connection was not made')
        raise PgRls::Errors::TenantNotFound
      end

      def with_tenant!(resource)
        PgRls.main_model.connection_pool.with_connection do
          tenant = switch_tenant!(resource)

          yield(tenant).presence if block_given?
        ensure
          reset_rls! unless PgRls.test_inline_tenant == true
        end
      end

      def fetch
        fetch!
      rescue ActiveRecord::StatementInvalid, ActiveRecord::RecordNotFound
        nil
      end

      def fetch!
        PgRls::Current::Context.tenant ||= PgRls.main_model.find_by!(
          tenant_id: PgRls.connection_class.connection.execute(
            "SELECT current_setting('rls.tenant_id')"
          ).getvalue(0, 0)
        )
      end

      def reset_rls!
        PgRls.execute_rls_in_shards do |connection_class|
          connection_class.transaction do
            connection_class.connection.execute('RESET rls.tenant_id')
          end
        end

        clear_current_context
        nil
      end

      def set_rls!(tenant_id)
        PgRls.execute_rls_in_shards do |connection_class|
          connection_class.transaction do
            connection_class.connection.execute(format('SET rls.tenant_id = %s',
                                                       connection_class.connection.quote(tenant_id)))
          end
        end
      end

      private

      def switch_tenant!(resource)
        tenant = find_tenant(resource)

        set_rls!(tenant.tenant_id)

        tenant
      rescue NoMethodError
        raise PgRls::Errors::TenantNotFound
      end

      def find_tenant(resource)
        reset_rls!

        tenant = nil

        PgRls.search_methods.each do |method|
          break if tenant.present?

          tenant = find_tenant_by_method(resource, method)
        end

        raise PgRls::Errors::TenantNotFound if tenant.blank?

        tenant
      end

      def find_tenant_by_method(resource, method)
        look_up_value = resource.is_a?(PgRls.main_model) ? resource.send(method) : resource
        PgRls.main_model.send("find_by_#{method}!", look_up_value)
      rescue ActiveRecord::RecordNotFound
        nil
      end

      def clear_current_context
        PgRls::Current::Context.clear_all
      end
    end
  end
end
