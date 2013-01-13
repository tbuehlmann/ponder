module Ponder
  module IRC
    module Events
      class Quit
        attr_reader :user, :channels, :message

        def initialize(user, channels, message)
          @user = user
          @channels = channels
          @message = message
        end
      end
    end
  end
end
