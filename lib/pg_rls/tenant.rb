# frozen_string_literal: true

module PgRls
  # Tenant Controller
  module Tenant
    class << self
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
        PgRls.main_model.find_by!(
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

        nil
      end

      private

      def switch_tenant!(resource)
        # rubocop: disable Rails/IgnoredColumnsAssignment
        PgRls.main_model.ignored_columns = []
        # rubocop: enable Rails/IgnoredColumnsAssignment

        tenant = find_tenant(resource)

        PgRls.execute_rls_in_shards do |connection_class|
          connection_class.transaction do
            connection_class.connection.execute(format('SET rls.tenant_id = %s',
                                                       connection_class.connection.quote(tenant.tenant_id)))
          end
        end

        tenant
      rescue NoMethodError
        raise PgRls::Errors::TenantNotFound
      end

      def find_tenant(resource)
        raise PgRls::Errors::AdminUsername if PgRls.admin_connection?

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
    end
  end
end
