module Ponder
  class Callback
    LISTENED_TYPES = [:connect, :channel, :query, :join, :part, :quit, :nickchange, :kick] # + 3-digit numbers
    
    attr_reader :type
    
    def initialize(type = :channel, match = //, proc = Proc.new {})
      if (type.is_a?(Symbol) || type.is_a?(String))
        @type = type.to_sym
        
        unless (LISTENED_TYPES.include?(@type) || @type =~ /^\d\d\d$/)
          raise TypeError, "#{@type} is an unsupported type"
        end
      else
        raise TypeError, "#{type} must be a String, Symbol or 3-digit number"
      end
      
      if match.is_a?(Regexp)
        @match = match
      else
        raise TypeError, "#{match} must be a Regexp"
      end
      
      @proc = proc
    end
    
    def call(type, env)
      if (type == :channel) || (type == :query)
          @proc.call(env) if env[:message] =~ @match
      else
        @proc.call(env)
      end
    end
  end
end
