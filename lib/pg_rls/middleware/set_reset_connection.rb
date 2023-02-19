# frozen_string_literal: true

module PgRls
  module Middleware
    # Set RLS if sessions present.
    class SetResetConnection
      def initialize(app)
        @app = app
      end

      def call(env)
        tenant = load_tenant_thought_session(env)

        return @app.call(env) if tenant.blank?

        PgRls::Tenant.with_tenant(tenant) { @app.call(env) }
      rescue ActiveRecord::RecordNotFound => e
        raise e unless rails_active_storage_request?(env)

        [404, { 'Content-Type' => 'text/plain' }, ['Could not find asset']]
      end

      def load_session_cookie_value(env)
        cookie_string = env['HTTP_COOKIE']
        return if cookie_string.nil?

        cookie_regex = /#{PgRls.session_key}=([^;]+)/
        match = cookie_regex.match(cookie_string)
        match[1] if match
      end

      def load_tenant_thought_session(env)
        cookie = load_session_cookie_value(env)

        return if cookie.blank?

        sessions = Rails.cache.read("#{PgRls.session_prefix}#{Digest::SHA256.hexdigest(cookie)}")
        sessions['_tenant']
      end

      def rails_active_storage_request?(env)
        env['PATH_INFO'].start_with?('/rails/active_storage/')
      end
    end
  end
end
