module Ponder
  class Callback
    attr_reader :options

    def initialize(pattern = //, options = {}, proc = Proc.new {})
      unless pattern.is_a?(Regexp)
        raise TypeError, "Regexp for pattern expected, got #{pattern.class}"
      end
      unless proc.is_a?(Proc)
        raise TypeError, "Proc for proc expected, got #{proc.class}"
      end

      @pattern = pattern
      @proc = proc
      @options = options
    end

    def matching?(event)
      if [:channel, :query].include? event[:type]
        event[:message] =~ @pattern ? true : false
      elsif event[:type] == :topic
        event[:topic] =~ @pattern ? true : false
      else
        true
      end
    end

    def call(event)
      @proc.call(event) if matching?(event)
    end
  end
end
