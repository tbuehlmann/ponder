require 'core_ext/array'
require 'fiber'
require 'fileutils'
require 'ostruct'
require 'set'
require 'ponder/callback'
require 'ponder/connection'
require 'ponder/event'
require 'ponder/irc'
require 'ponder/isupport'
require 'ponder/logger/twoflogger'
require 'ponder/logger/blind_io'
require 'ponder/channel'
require 'ponder/channel_list'
require 'ponder/user'
require 'ponder/user_list'

module Ponder
  class Thaum
    include IRC

    attr_reader :config, :callbacks, :isupport, :channel_list, :user_list, :connection
    attr_accessor :connected, :logger, :console_logger, :deferrables

    def initialize(&block)
      # default settings
      @config = OpenStruct.new(
        :server             => 'localhost',
        :port               => 6667,
        :ssl                => false,
        :nick               => 'Ponder',
        :username           => 'Ponder',
        :real_name          => 'Ponder',
        :verbose            => true,
        :logging            => false,
        :reconnect          => true,
        :reconnect_interval => 30
      )

      # custom settings
      block.call(@config) if block_given?

      # setting up loggers
      @console_logger = if @config.verbose
        Logger::Twoflogger.new($stdout)
      else
        Logger::BlindIo.new
      end

      @logger = if @config.logging
        if @config.logger
          @config.logger
        else
          log_path = File.join(ROOT, 'logs', 'log.log')
          log_dir = File.dirname(log_path)
          FileUtils.mkdir_p(log_dir) unless File.exist?(log_dir)
          Logger::Twoflogger.new(log_path, File::WRONLY | File::APPEND)
        end
      else
        Logger::BlindIo.new
      end

      # when using methods like #get_topic or #whois, a Deferrable object will wait
      # for the response and call a callback. these Deferrables are stored in this Set
      @deferrables = Set.new

      @connected = false

      # user callbacks
      @callbacks = Hash.new { |hash, key| hash[key] = [] }

      # setting up isuport
      @isupport = ISupport.new

      setup_default_callbacks
      setup_channel_and_user_tracking
    end

    def on(event_type = :channel, match = //, *options, &block)
      options = options.extract_options!
      callback = Callback.new(match, options, block)
      @callbacks[event_type] << callback
      callback
    end

    def connect
      @logger.info '-- Starting Ponder'
      @console_logger.info '-- Starting Ponder'

      EventMachine::run do
        @connection = EventMachine::connect(@config.server, @config.port, Connection, self)
      end
    end

    # parsing incoming traffic
    def parse(message)
      message.chomp!
      @logger.info "<< #{message}"
      @console_logger.info "<< #{message}"

      if message =~ /^PING \S+$/
        raw message.sub(/PING/, 'PONG')
      else
       event = Event.parse(message, @isupport['CHANTYPES'])
       parse_event(event) unless event.empty?
      end

      # if there are pending deferrabels, check if the message suits their matching pattern
      @deferrables.each { |d| d.try(message) }
    end

    # Each matching callback will run in its own fiber. So the execution
    # of code can be stopped until necessary data (eg from a WHOIS) gets in.
    #
    # The callback processing is exception handled, so the EM reactor won't die
    # from exceptions.
    def process_callbacks(event_type, event)
      @callbacks[event_type].each do |callback|
        fiber = Fiber.new do
          begin
            callback.call(event)
          rescue => e
            [@logger, @console_logger].each do |logger|
              logger.error("-- #{e.class}: #{e.message}")
              e.backtrace.each { |line| logger.error("-- #{line}") }
            end
          end
        end

        # If the callback has a :defer option, call it in a thread
        # from the EM thread pool. Else call it in the reactor thread.
        if callback.options[:defer]
          EM.defer(fiber.resume)
        else
          fiber.resume
        end
      end
    end

    private

    # parses incoming traffic (types)
    def parse_event(event)
      if ((event[:type] == 376) || (event[:type] == 422)) && !@connected
        @connected = true
        process_callbacks(:connect, event)
      end

      process_callbacks(event[:type], event)
    end

    # Default callbacks for PING, VERSION, TIME and ISUPPORT processing.
    def setup_default_callbacks
      on :query, /^\001PING \d+\001$/ do |event_data|
        time = event_data[:message].scan(/\d+/)[0]
        notice event_data[:nick], "\001PING #{time}\001"
      end

      on :query, /^\001VERSION\001$/ do |event_data|
        notice event_data[:nick], "\001VERSION Ponder #{Ponder::VERSION} (https://github.com/tbuehlmann/ponder)\001"
      end

      on :query, /^\001TIME\001$/ do |event_data|
        notice event_data[:nick], "\001TIME #{Time.now.strftime('%a %b %d %H:%M:%S %Y')}\001"
      end

      on 005 do |event_data|
        @isupport.parse event_data[:params]
      end
    end

    def setup_channel_and_user_tracking
      @channel_list = ChannelList.new
      @user_list = UserList.new

      on :connect do
        thaum = User.new(@config.nick, self)
        @user_list.add(thaum, true)
      end

      on :join do |event_data|
        if event_data[:nick] == @config.nick
          channel = Channel.new(event_data[:channel], self)
          @channel_list.add channel
          thaum = @user_list.find(@config.nick)
          channel.add_user(thaum, [])
        else
          channel = @channel_list.find(event_data[:channel])
          user = @user_list.find(event_data[:nick])
          unless user
            user = User.new(event_data[:nick], self)
            @user_list.add user
          end

          channel.add_user(user, [])
        end
      end

      on 353 do |event_data|
        channel_name = event_data[:params].split(' ')[2]
        channel = @channel_list.find(channel_name)
        nicks_with_prefixes = event_data[:params].scan(/:(.*)/)[0][0].split(' ')
        nicks, prefixes = [], []
        channel_prefixes = @isupport['PREFIX'].values.map do |p|
          Regexp.escape(p)
        end.join('|')

        nicks_with_prefixes.each do |nick_with_prefixes|
          nick = nick_with_prefixes.gsub(/#{channel_prefixes}/, '')
          prefixes = nick_with_prefixes.scan(/#{channel_prefixes}/)
          
          user = @user_list.find(nick)
          unless user
            user = User.new(nick, self)
            @user_list.add(user)
          end

          channel.add_user(user, prefixes)
        end
      end

      on :part do |event_data|
        channel = @channel_list.find(event_data[:channel])
        if event_data[:nick] == @config.nick
          # Remove the channel from the channel_list.
          @channel_list.remove(event_data[:channel])

          # Remove all users from the user_list that do not share channels
          # with the Thaum.
          all_known_users = @channel_list.channels.values.map do |channel|
            channel.users.values.map(&:first)
          end

          @user_list.kill_zombie_users(all_known_users)
        else
          channel.remove_user event_data[:nick]
          remove_user = @channel_list.channels.values.none? do |channel|
            channel.has_user?(event_data[:nick])
          end

          @user_list.remove(event_data[:nick]) if remove_user
        end
      end

      on :kick do |event_data|
        channel = @channel_list.find(event_data[:channel])
        if event_data[:victim] == @config.nick
          # Remove the channel from the channel_list.
          @channel_list.remove(event_data[:channel])

          # Remove all users from the user_list that do not share channels
          # with the Thaum.
          all_known_users = @channel_list.channels.values.map do |channel|
            channel.users.values.map(&:first)
          end

          @user_list.kill_zombie_users(all_known_users)
        else
          channel.remove_user event_data[:victim]
          remove_user = @channel_list.channels.values.none? do |channel|
            channel.has_user?(event_data[:victim])
          end

          @user_list.remove(event_data[:victim]) if remove_user
        end
      end

      on :quit do |event_data|
        if event_data[:nick] == @config.nick
          @channel_list.clear
          @user_list.clear
        else
          @channel_list.remove_user event_data[:nick]
          @user_list.remove event_data[:nick]
        end
      end

      on :disconnect do |event_data|
        @channel_list.clear
        @user_list.clear
      end

      # TODO: on :mode
    end
  end
end
