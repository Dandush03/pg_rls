# frozen_string_literal: true

PgRls.setup do |config|
  config.class_name = :Tenant
  config.table_name = :tenants
  config.search_methods = %i[subdomain tenant_id id]

  # config.username = Rails.application.credentials.dig(:database, :username)
  # config.password = Rails.application.credentials.dig(:database, :password)

  # config.rls_role_group = "rls_group"
  # config.schema = "public"
end
