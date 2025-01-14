# frozen_string_literal: true

module PgRls
  # Deprecator Module
  module Deprecation
    def self.warn(message)
      logger.warn(message)
    end

    def self.logger
      @logger ||= ::ActiveSupport::Deprecation.new(PgRls::VERSION, "PgRls")
    end
  end
end
