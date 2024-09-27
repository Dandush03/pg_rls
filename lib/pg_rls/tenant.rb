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
          reset_rls! unless PgRls.test_inline_tenant == true || PgRls::Current::Context.tenant.blank?
        end
      end

      def fetch
        fetch!
      rescue ActiveRecord::StatementInvalid, ActiveRecord::RecordNotFound
        nil
      end

      def fetch!
        PgRls::Current::Context.tenant ||= PgRls.main_model.connection_pool.with_connection do |connection|
          tenant_id = get_tenant_id(connection)
          if tenant_id.present?
            PgRls.main_model.find_by!(
              tenant_id:
            )
          end
        end
      end

      # rubocop:disable Lint/RescueStandardError
      # rubocop:disable Lint/UselessAssignment
      def get_tenant_id(connection)
        connection.execute("SELECT current_setting('rls.tenant_id')").getvalue(0, 0)
      rescue => e
        nil
      end
      # rubocop:enable Lint/RescueStandardError
      # rubocop:enable Lint/UselessAssignment

      def reset_rls!
        PgRls.execute_rls_in_shards do |connection_class|
          connection_class.connection_pool.with_connection do |connection|
            connection.transaction do
              connection.execute('RESET rls.tenant_id')
            end
          end
        end

        PgRls::Current::Context.clear_all
        nil
      end

      def set_rls!(tenant)
        tenant_id = tenant.tenant_id
        PgRls.execute_rls_in_shards do |connection_class|
          connection_class.connection_pool.with_connection do |connection|
            connection.transaction do
              connection.execute(format('SET rls.tenant_id = %s',
                                        connection.quote(tenant_id)))
            end
          end
        end
        PgRls::Current::Context.clear_all
        PgRls::Current::Context.tenant = tenant
      end

      def on_find_each(ids: [], scope: nil, &)
        raise 'Invalid Scope' if scope.present? && PgRls.main_model != scope.klass

        result = []

        query = build_on_each_query(ids, scope)

        query.find_each do |tenant|
          result << { tenant_id: tenant.id, result: with_tenant!(tenant, &) }
        end

        result
      end

      private

      def build_on_each_query(ids, scope)
        return PgRls.main_model.all if ids.empty? && scope.blank?

        return PgRls.main_model.where(id: ids) if scope.blank?

        return scope.where(id: ids) if ids.present?

        scope
      end

      def switch_tenant!(resource)
        tenant = find_tenant(resource)

        PgRls.establish_new_connection! if PgRls.admin_connection?
        set_rls!(tenant)

        tenant
      rescue NoMethodError
        raise PgRls::Errors::TenantNotFound
      ensure
        reset_rls! if tenant.blank?
      end

      def find_tenant(resource)
        tenant = nil

        PgRls.search_methods.each do |method|
          break if tenant.present?

          tenant = find_tenant_by_method(resource, method)
        end

        reset_rls! if reset_rls?(tenant)
        raise PgRls::Errors::TenantNotFound if tenant.blank?

        tenant
      end

      def reset_rls?(tenant)
        PgRls::Current::Context.tenant.present? && tenant.present? && PgRls::Current::Context.tenant != tenant
      end

      def find_tenant_by_method(resource, method)
        return resource if resource.is_a?(PgRls.main_model)

        PgRls.main_model.unscoped.send(:"find_by_#{method}!", resource)
      rescue ActiveRecord::RecordNotFound
        nil
      end
    end
  end
end
