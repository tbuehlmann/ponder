module Ponder
  class Callback
    LISTENED_TYPES = [:connect, :channel, :query, :join, :part, :quit, :nickchange, :kick, :topic, :disconnect] # + 3-digit numbers

    def initialize(event_type = :channel, match = //, proc = Proc.new {})
      unless self.class::LISTENED_TYPES.include?(event_type) || event_type.is_a?(Integer)
        raise TypeError, "#{event_type} is an unsupported event-type"
      end

      self.match = match
      self.proc = proc
    end

    def call(event_type, event_data = {})
      if (event_type == :channel) || (event_type == :query)
        @proc.call(event_data) if event_data[:message] =~ @match
      elsif event_type == :topic
        @proc.call(event_data) if event_data[:topic] =~ @match
      else
        @proc.call(event_data)
      end
    end

    private

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
