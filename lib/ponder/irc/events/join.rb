module Ponder
  module IRC
    module Events
      class Join
        attr_reader :user, :channel

        def initialize(user, channel)
          @user = user
          @channel = channel
        end
      end
    end
  end
end
