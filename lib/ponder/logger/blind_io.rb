module Ponder
  class BlindIo
    [:debug, :info, :warn, :error, :fatal].each do |severity_method|
      send(:define_method, severity_method, Proc.new { |*args, &block| nil })
    end

    def method_missing(*args, &block)
    end
  end
end

