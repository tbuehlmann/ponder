module Ponder
  module IRC
    module Events
      class Part
        attr_reader :user, :channel, :message

        def initialize(user, channel, message)
          @user = user
          @channel = channel
          @message = message
        end
      end
    end
  end
end
