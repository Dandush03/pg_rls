# frozen_string_literal: true

module PgRls
  module Errors
    class AdminUsername < StandardError
      def initialize(msg = nil)
        msg ||= 'Cannot set or reset tenant for admin user'
        super(msg)
      end
    end
  end
end
