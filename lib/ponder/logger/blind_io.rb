module Ponder
  module Logger
    class BlindIo
      def initialize
        [:debug, :info, :warn, :error, :fatal, :unknown, :start_logging, :stop_logging].each do |method_name|
          self.class.send(:define_method, method_name, Proc.new { |*args| nil })
        end
      end
    end
  end
end
