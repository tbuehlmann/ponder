require 'logger'

module Ponder
  module Logging
    class Twoflogger < ::Logger
      def initialize(*args)
        super(*args)
        self.formatter = proc do |severity, datetime, progname, msg|
          "#{severity} #{datetime.strftime('%Y-%m-%d %H:%M:%S')} #{msg}\n"
        end
      end

      def silence
        old_logger_level = self.level
        self.level = ERROR
        yield if block_given?
      ensure
        self.level = old_logger_level
      end
    end
  end
end
