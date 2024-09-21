require 'logger'

module PgRls
  class Logger
    def initialize
      @logger = ::Logger.new(STDOUT) # You can output to a file if needed
      @logger.level = ::Logger::DEBUG
    end

    def log(message, level: :info)
      case level
      when :debug
        @logger.debug(message)
      when :info
        @logger.info(message)
      when :warn
        @logger.warn(message)
      when :error
        @logger.error(message)
      else
        @logger.info(message)
      end
    end

    def deprecation_warning(message)
      log("[DEPRECATION WARNING]: #{message}", level: :warn)
    end
  end
end
