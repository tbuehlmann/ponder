module Ponder
  module Logging
    class BlindIo
      %w(debug info warn error fatal unknown silence method_missing).each do |method_name|
        define_method(method_name) { |*args, &block| }
      end
    end
  end
end
