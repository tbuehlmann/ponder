module Ponder
  module IRC
    module Events
      class Message
        attr_reader :user, :body

        def initialize(user, body, channel = nil)
          @user = user
          @body = body

          if channel
            @channel = channel

            def self.channel
              @channel
            end
          end
        end

        def =~(pattern)
          @body =~ pattern
        end
      end
    end
  end
end
