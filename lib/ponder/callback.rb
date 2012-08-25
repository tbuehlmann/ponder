module Ponder
  class Callback
    LISTENED_TYPES = [:connect, :channel, :query, :join, :part, :quit, :nickchange, :kick, :topic, :disconnect] # + 3-digit numbers

    attr_reader :options

    def initialize(event_type = :channel, match = //, options = {}, proc = Proc.new {})
      unless self.class::LISTENED_TYPES.include?(event_type) || event_type.is_a?(Integer)
        raise TypeError, "#{event_type} is an unsupported event-type"
      end

      self.match = match
      self.proc = proc
      @options = options
    end

    def call(event)
      if (event[:type] == :channel) || (event[:type] == :query)
        @proc.call(event) if event[:message] =~ @match
      elsif event[:type] == :topic
        @proc.call(event) if event[:topic] =~ @match
      else
        @proc.call(event)
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
