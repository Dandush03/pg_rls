# frozen_string_literal: true

module PgRls
  # Main PgRls Error Class
  class Error < StandardError
    class InvalidConnectionConfig < Error; end
    class InvalidSearchInput < Error; end
    class TenantNotFound < Error; end
  end
end
