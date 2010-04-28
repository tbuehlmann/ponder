module Ponder
  class Callback
    LISTENED_TYPES = [:connect, :channel, :query, :join, :part, :quit, :nickchange, :kick] # + 3-digit numbers
    
    attr_reader :event_type
    
    def initialize(event_type = :channel, match = //, proc = Proc.new {})
      self.event_type = event_type
      self.match = match
      self.proc = proc
    end
    
    def call(event_type, event_data = {})
      if (event_type == :channel) || (event_type == :query)
        @proc.call(event_data) if event_data[:message] =~ @match
      else
        @proc.call(event_data)
      end
    end
    
    private
    
    def event_type=(event_type)
      if LISTENED_TYPES.include?(event_type) || event_type.is_a?(Integer)
        @event_type = event_type
      else
        raise TypeError, "#{type} is an unsupported event-type"
      end
    end
    
    def match=(match)
      if match.is_a?(Regexp)
        @match = match
      else
        raise TypeError, "#{match} must be a Regexp"
      end
    end
    
    def proc=(proc)
      if proc.is_a?(Proc)
        @proc = proc
      else
        raise TypeError, "#{proc} must be a Proc"
      end
    end
  end
end
