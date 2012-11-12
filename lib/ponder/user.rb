require 'thread'
require 'ponder/recipient'

module Ponder
  class User < Recipient
    def initialize(nick, thaum)
      super
      @nick = nick
    end

    def nick
      synchronize do
        @nick
      end
    end

    def message(message)
      raw "PRIVMSG #{@nick} :#{message}"
    end

    def inspect
      "#<User nick=#{@nick.inspect}>"
    end
  end
end
