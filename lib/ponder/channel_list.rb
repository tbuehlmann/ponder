module Ponder
  class ChannelList
    attr_reader :channels

    def initialize
      @channels = Set.new
      @mutex = Mutex.new
    end

    # Add a Channel to the ChannelList.
    def add(channel)
      @mutex.synchronize do
        @channels << channel
      end
    end

    # Removes a Channel from the ChannelList.
    def remove(channel_or_channel_name)
      @mutex.synchronize do
        if channel_or_channel_name.is_a?(String)
          channel_or_channel_name = find(channel_or_channel_name)
        end
 
        @channels.delete(channel_or_channel_name)
      end
    end

    # Removes a User from all Channels from the ChannelList.
    # Returning a Set of Channels in which the User was.
    def remove_user(nick)
      @mutex.synchronize do
        channels = Set.new

        @channels.each do |channel|
          if channel.remove_user(nick)
            channels << channel
          end
        end

        channels
      end
    end

    # Finding a Channel using the lowercased Channel name.
    def find(channel_name)
      @channels.find { |c| c.name.downcase == channel_name.downcase }
    end

    # Removes all Channels from the ChannelList and returns them.
    def clear
      @mutex.synchronize do
        channels = @channels.dup
        @channels.clear
        channels
      end
    end

    # Returns a Set of all Users that are in one of the Channels from the
    # ChannelList.
    def users
      users = Set.new

      @channels.each do |channel|
        users.merge channel.users
      end

      users
    end
  end
end
