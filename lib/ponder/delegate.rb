module Ponder
  module Delegate
    def delegate
      thaum = self
      
      (IRC.instance_methods + [:configure, :on, :connect, :reload!, :reloading?]).each do |method|
         Object.send(:define_method, method) { |*args, &block| thaum.send(method, *args, &block) }
      end
    end
  end
end
