require 'core_ext/array'
require 'fiber'
require 'fileutils'
require 'ostruct'
require 'set'
require 'ponder/async_irc'
require 'ponder/callback'
require 'ponder/connection'
require 'ponder/irc'
require 'ponder/isupport'
require 'ponder/logger/twoflogger'
require 'ponder/logger/blind_io'
require 'ponder/message_parser'

module Ponder
  class Thaum
    include IRC
    include AsyncIRC::Delegate

    attr_reader :config, :callbacks, :isupport
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

      # standard callbacks for PING, VERSION, TIME and Nickname is already in use
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

    def on(event_type = :channel, match = //, *options, &block)
      options = options.extract_options!
      callback = Callback.new(event_type, match, options, block)
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
       event = MessageParser.parse(message, @isupport['CHANTYPES'])
       parse_event(event) if event
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
  end
end
