# frozen_string_literal: true

module PgRls
  # Main PgRls Error Class
  class Error < StandardError
    class InvalidConnectionConfig < Error; end
  end
end
