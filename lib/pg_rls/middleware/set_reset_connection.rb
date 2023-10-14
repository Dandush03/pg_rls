# frozen_string_literal: true

module PgRls
  class FrozenConfiguration < StandardError; end

  def self.sessions
    @sessions ||= Redis.new(@session_store_server)
  end

  def self.session_prefix
    @session_prefix ||= begin
      store_default_warden_key = @session_store_default_warden_key || '2'

      "#{session_key_prefix}:#{store_default_warden_key}::"
    end
  end

  def self.session_store_server=(opts = {})
    raise Errors::FrozenConfiguration unless @sessions.nil?

    @session_store_server = opts.deep_symbolize_keys
  end

  def self.session_store_default_warden_key=(val)
    raise Errors::FrozenConfiguration unless @sessions.nil?

    @session_store_default_warden_key = val
  end

  def self.session_key_prefix
    @session_key_prefix ||= @session_key_prefix || @session_store_server[:key_prefix]
  end

  def self.session_key_prefix=(val)
    raise Errors::FrozenConfiguration unless @sessions.nil?

    @session_key_prefix = val
  end
end

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

        PgRls::Tenant.with_tenant!(tenant) { @app.call(env) }
      rescue PgRls::Errors::TenantNotFound
        @app.call(env)
      rescue ActiveRecord::RecordNotFound => e
        raise e unless rails_active_storage_request?(env)

        [404, { 'Content-Type' => 'text/plain' }, ['Could not find asset']]
      end

      def load_session_cookie_value(env)
        cookie_string = env['HTTP_COOKIE']
        return if cookie_string.nil?

        cookie_regex = /#{PgRls.session_key_prefix}=([^;]+)/
        match = cookie_regex.match(cookie_string)
        match[1] if match
      end

      def load_tenant_thought_session(env)
        cookie = load_session_cookie_value(env)

        return if cookie.blank?

        redis_session_key = "#{PgRls.session_prefix}#{Digest::SHA256.hexdigest(cookie)}"
        tenant_session = Marshal.load(PgRls.sessions.get(redis_session_key))

        return if tenant_session.blank?
        return if tenant_session['_tenant'].blank?

        tenant_session['_tenant'] if tenant_session.present?
      rescue TypeError
        nil
      end

      def rails_active_storage_request?(env)
        env['PATH_INFO'].start_with?('/rails/active_storage/')
      end
    end
  end
end
