# frozen_string_literal: true

module PgRls
  module Solo
    # Set and Fetch Tenant without loading a model
    class Tenant
      class << self
        attr_reader :tenant

        def switch!(resource)
          switch_tenant!(resource)
        rescue StandardError => e
          Rails.logger.info('connection was not made')
          raise e
        end

        def fetch
          @fetch ||= PgRls.connection_class.connection.execute(
            "SELECT current_setting('rls.tenant_id')"
          ).getvalue(0, 0)
        end

        def around(resource)
          switch_tenant!(resource)
          yield
        ensure
          reset_rls!
        end

        private

        def reset_rls!
          @fetch = nil
          @tenant = nil
          PgRls.connection_class.connection.execute('RESET rls.tenant_id')
        end

        def switch_tenant!(resource)
          connection_adapter = PgRls.connection_class

          raise PgRls::Errors::TenantNotFound if resource.blank?

          connection_adapter.connection.execute(format('SET rls.tenant_id = %s',
                                                       connection_adapter.connection.quote(resource)))
          "RLS changed to '#{resource}'"
        end
      end
    end
  end
end
