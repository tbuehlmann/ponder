# Adapted from Cinch:
# https://github.com/cinchrb/cinch/blob/master/lib/cinch/logger_list.rb

module Ponder
  module Logging
    class LoggerList < Array
      %w(debug info warn error fatal unknown).each do |method_name|
        define_method(method_name) do |*args, &block|
          each do |logger|
            logger.send(method_name, *args, &block)
          end
        end
      end

      def method_missing(method_name, *args, &block)
        each do |logger|
          logger.send(method_name, *args, &block)
        end
      end
    end
  end
end
