# frozen_string_literal: true

module PgRls
  # Deprecator Module
  module Deprecation
    attr_reader :invoked

    def self.warn(message, method) # OPCINAL SI LO AGREGAS AGREGA PRUEBAS
      @invoked ||= []
      return if @invoked.include?(method)

      @invoked << method
      logger.warn(message)
    end

    def self.logger
      @logger ||= ::ActiveSupport::Deprecation.new(PgRls::VERSION, "PgRls")
    end
  end
end
