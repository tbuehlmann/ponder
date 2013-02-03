module Ponder
  module IRC
    module Events
      class ChannelMode
        attr_reader :channel, :direction, :mode, :param
        def initialize(mode_change)
          @channel = mode_change[:channel]
          @direction = mode_change[:direction]
          @mode = mode_change[:mode]
          @param = mode_change[:param]
        end
      end
    end
  end
end
