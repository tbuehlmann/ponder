require 'thread'
require 'fiber'
require 'timeout'
require 'eventmachine'

module Ponder
  module AsyncIRC
    class Topic
      # number of seconds the deferrable will wait for a response before failing
      TIMEOUT = 15

      include EventMachine::Deferrable

      def initialize(channel, timeout_after, thaum)
        @channel = channel
        @thaum = thaum
        @fiber = Fiber.current

        self.timeout(timeout_after)
        self.callback { |args| @fiber.resume(args) }
        self.errback { @fiber.resume(nil) }

        @thaum.deferrables.add self
        @thaum.raw "TOPIC #{@channel}"
      end

      def try(message)
        if message =~ /:\S+ (331|332|403|442) \S+ #{Regexp.escape(@channel)} :/i
          case $1
          when '331'
            succeed({:raw_numeric => 331, :message => 'No topic is set'})
          when '332'
            succeed({:raw_numeric => 332, :message => message.scan(/ :(.*)/)[0][0]})
          when '403'
            succeed({:raw_numeric => 403, :message => 'No such channel'})
          when '442'
            succeed({:raw_numeric => 442, :message => "You're not on that channel"})
          end
        end
      end

      def succeed(*args)
        @thaum.deferrables.delete self
        set_deferred_status :succeeded, *args
      end

      def fail(*args)
        @thaum.deferrables.delete self
        set_deferred_status :failed
      end
   end

    class Whois
      # number of seconds the deferrable will wait for a response before failing
      TIMEOUT = 15

      include EventMachine::Deferrable

      def initialize(nick, timeout_after, thaum)
        @nick = nick
        @thaum = thaum
        @whois_data = {}
        @fiber = Fiber.current

        self.timeout(timeout_after)
        self.callback { |args| @fiber.resume(args) }
        self.errback { @fiber.resume(nil) }

        @thaum.deferrables.add self
        @thaum.raw "WHOIS #{@nick}"
      end

      def try(message)
        if message =~ /^:\S+ (307|311|312|318|319|330|401) \S+ #{Regexp.escape(@nick)}/i
          case $1
          when '307', '330'
            @whois_data[:registered] = true
          when '311'
            message = message.scan(/^:\S+ 311 \S+ (\S+) :?(\S+) (\S+) \* :(.*)$/)[0]
            @whois_data[:nick]      = message[0]
            @whois_data[:username]  = message[1]
            @whois_data[:host]      = message[2]
            @whois_data[:real_name] = message[3]
          when '312'
            message = message.scan(/^:\S+ 312 \S+ \S+ (\S+) :(.*)/)[0]
            @whois_data[:server] = {:address => message[0], :name => message[1]}
          when '318'
            succeed @whois_data
          when '319'
            channels_with_mode = message.scan(/^:\S+ 319 \S+ \S+ :(.*)/)[0][0].split(' ')
            @whois_data[:channels] = {}
            channels_with_mode.each do |c|
              @whois_data[:channels][c.scan(/(.)?(#\S+)/)[0][1]] = c.scan(/(.)?(#\S+)/)[0][0]
            end
          when '401'
            succeed false
          end
        end
      end

      def succeed(*args)
        @thaum.deferrables.delete self
        set_deferred_status :succeeded, *args
      end

      def fail(*args)
        @thaum.deferrables.delete self
        set_deferred_status :failed
      end
    end

    class Channel
      # number of seconds the deferrable will wait for a response before failing
      TIMEOUT = 15

      include EventMachine::Deferrable

      def initialize(channel, timeout_after, thaum)
        @channel = channel
        @thaum = thaum
        @channel_information = {}
        @fiber = Fiber.current

        self.timeout(timeout_after)
        self.callback { |args| @fiber.resume(args) }
        self.errback { @fiber.resume(nil) }

        @thaum.deferrables.add self
        @thaum.raw "MODE #{@channel}"
      end

      def try(message)
        if message =~ /:\S+ (324|329|403|442) \S+ #{Regexp.escape(@channel)}/i
          case $1
          when '324'
            @channel_information[:modes] = message.scan(/^:\S+ 324 \S+ \S+ \+(\w*)/)[0][0].split('')
            limit = message.scan(/^:\S+ 324 \S+ \S+ \+\w* (\w*)/)[0]
            @channel_information[:channel_limit] = limit[0].to_i if limit
          when '329'
            @channel_information[:created_at] = Time.at(message.scan(/^:\S+ 329 \S+ \S+ (\d+)/)[0][0].to_i)
            succeed @channel_information
          when '403', '442'
            succeed false
          end
        end
      end

      def succeed(*args)
        @thaum.deferrables.delete self
        set_deferred_status :succeeded, *args
      end

      def fail(*args)
        @thaum.deferrables.delete self
        set_deferred_status :failed
      end
    end

    module Delegate
      def get_topic(channel, timeout_after = AsyncIRC::Topic::TIMEOUT)
        AsyncIRC::Topic.new(channel, timeout_after, self)
        return Fiber.yield
      end

      def whois(nick, timeout_after = AsyncIRC::Whois::TIMEOUT)
        AsyncIRC::Whois.new(nick, timeout_after, self)
        return Fiber.yield
      end

      def channel_info(channel, timeout_after = AsyncIRC::Channel::TIMEOUT)
        AsyncIRC::Channel.new(channel, timeout_after, self)
        return Fiber.yield
      end
    end
  end
end
