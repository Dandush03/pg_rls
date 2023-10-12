module PgRls
  module Errors
    class RakeOnlyError < StandardError
      def initialize(msg = nil)
        msg ||= 'This method can only be executed through rake tasks'
        super(msg)
      end
    end
  end
end
