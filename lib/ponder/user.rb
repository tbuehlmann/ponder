require 'thread'
require 'ponder/recipient'

module Ponder
  class User < Recipient
    attr_reader :nick
    
    def initialize(nick, thaum)
      super
      @nick = nick
    end

    def nick
      synchronize do
        @nick
      end
    end

    # Updates the properties of an user.
    def whois
      fiber = Fiber.current
      callbacks = {}

      # User is online.
      callbacks[311] = @thaum.on(311) do |event_data|
        nick = event_data[:params].split(' ')[1]
        if nick.downcase == @nick.downcase
          @online = true
          # TODO: Add properties.
        end
      end

      # User is not online.
      callbacks[401] = @thaum.on(401) do |event_data|
        nick = event_data[:params].split(' ')[1]
        if nick.downcase == @nick.downcase
          @online = false
          fiber.resume
        end
      end

      # End of WHOIS.
      callbacks[318] = @thaum.on(318) do |event_data|
        nick = event_data[:params].split(' ')[1]
        if nick.downcase == @nick.downcase
          fiber.resume
        end
      end

      raw "WHOIS #{@nick}"
      Fiber.yield

      callbacks.each do |type, callback|
        @thaum.callbacks[type].delete(callback)
      end

      self
    end

    def online?
      if @thaum.user_list.find(@nick)
        true
      else
        whois if @online.nil?
        @online
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
