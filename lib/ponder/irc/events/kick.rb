module Ponder
  module IRC
    module Events
      class Kick
        attr_reader :kicker, :victim, :channel, :message

        def initialize(kicker, victim, channel, message)
          @kicker = kicker
          @victim = victim
          @channel = channel
          @message = message
        end
      end
    end
  end
end
