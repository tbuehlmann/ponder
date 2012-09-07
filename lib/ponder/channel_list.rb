require 'thread'
require 'set'

module Ponder
  class ChannelList
    def initialize
      @channels = {}
      @mutex = Mutex.new
    end

    def channels
      @mutex.synchronize do
        @channels
      end
    end

    def add(channel)
      @mutex.synchronize do
        @channels[channel.name.downcase] = channel
      end
    end

    def remove(channel_or_channel_name)
      @mutex.synchronize do
        case channel_or_channel_name
        when String
          @channels.delete channel_or_channel_name
        when Channel
          @channels.delete_if { |lowercased_channel_name, channel| channel == channel_or_channel_name} 
        end
      end
    end

    def remove_user(nick)
      @mutex.synchronize do
        @channels.values.each do |channel|
          channel.remove_user nick
        end
      end
    end

    def find(channel_name)
      @mutex.synchronize do
        @channels[channel_name.downcase]
      end
    end

    def clear
      @mutex.synchronize do
        @channels.clear
      end
    end

    def users
      @mutex.synchronize do
        users = Set.new
        @channels.values.each do |channel|
          channel.users.each_value do |user_and_prefixes|
            users.add user_and_prefixes.first
          end
        end
        users.to_a
      end
    end
  end
end
