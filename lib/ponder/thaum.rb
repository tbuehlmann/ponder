require 'ponder/callback'
require 'ponder/connection'
require 'ponder/irc'
require 'ponder/async_irc'
require 'ponder/filter'
require 'ostruct'

module Ponder
  class Thaum
    include IRC
    include AsyncIRC
    
    if RUBY_VERSION >= '1.9'
      require 'ponder/delegate'
      include Delegate
    end
    
    attr_reader :config
    attr_accessor :connected, :traffic_logger, :error_logger, :console_logger, :empty_logger
    
    def initialize
      @config = OpenStruct.new(:server             => 'localhost',
                               :port               => 6667,
                               :nick               => 'Ponder',
                               :username           => 'Ponder',
                               :real_name          => 'Ponder',
                               :verbose            => true,
                               :logging            => false,
                               :reconnect          => true,
                               :reconnect_interval => 30,
                               :auto_rename        => false
                              )
      
      @empty_logger   = Logger::BlindIo.new
      @traffic_logger = @empty_logger
      @error_logger   = @empty_logger
      @console_logger = Logger::Twoflogger.new($stdout)
      
      @observer_queues = {}
      
      @connected = false
      @reloading = false
      
      # user callbacks
      @callbacks = Hash.new { |hash, key| hash[key] = [] }
      
      # standard callbacks for PING, VERSION, TIME and Nickname is already in use
      on :query, /^\001PING \d+\001$/ do |env|
        time = env[:message].scan(/\d+/)[0]
        notice env[:nick], "\001PING #{time}\001"
      end
      
      on :query, /^\001VERSION\001$/ do |env|
        notice env[:nick], "\001VERSION Ponder #{Ponder::VERSION} (http://github.com/tbuehlmann/ponder)\001"
      end
      
      on :query, /^\001TIME\001$/ do |env|
        notice env[:nick], "\001TIME #{Time.now.strftime('%a %b %d %H:%M:%S %Y')}\001"
      end
      
      on 433 do
        rename "#{@config.nick}#{rand(10)}#{rand(10)}#{rand(10)}"
      end
      
      # before and after filter
      @before_filters = Hash.new { |hash, key| hash[key] = [] }
      @after_filters = Hash.new { |hash, key| hash[key] = [] }
    end
    
    def configure(&block)
      unless @reloading
        block.call(@config)
        
        # logger changes (if differing from initialize)
        if @config.logging
          @traffic_logger = @config.traffic_logger ? @config.traffic_logger : Logger::Twoflogger.new(Ponder.root.join('logs', 'traffic.log'))
          @error_logger = @config.error_logger ? @config.error_logger : Logger::Twoflogger.new(Ponder.root.join('logs', 'error.log'))
        end
        
        unless @config.verbose
          @console_logger = @empty_logger
        end
        
        # remove auto_rename callback (if differing from initialize)
        unless @config.auto_rename
          @callbacks.delete(433)
        end
      end
    end
    
    def on(event_types = [:channel], match = //, &block)
      if event_types.is_a?(Array)
        callbacks = event_types.map { |event_type| Callback.new(event_type, match, block) }
      else
        callbacks = [Callback.new(event_types, match, block)]
        event_types = [event_types]
      end
      
      callbacks.each_with_index do |callback, index|
        @callbacks[event_types[index]] << callback
      end
    end
    
    def connect
      unless @reloading
        @traffic_logger.start_logging
        @error_logger.start_logging
        @console_logger.start_logging
        
        @traffic_logger.info '-- Starting Ponder'
        @console_logger.info '-- Starting Ponder'
        
        EventMachine::run do
          @connection = EventMachine::connect(@config.server, @config.port, Connection, self)
        end
      end
    end
    
    def reload!
      @reloading = true
      @callbacks.clear
      load $0
      @reloading = false
    end
    
    def reloading?
      @reloading
    end
    
    # parsing incoming traffic
    def parse(message)
      message.chomp!
      @traffic_logger.info "<< #{message}"
      @console_logger.info "<< #{message}"
      
      case message
      when /^PING \S+$/
        raw message.sub(/PING/, 'PONG')
      
      when /^:\S+ (\d\d\d) /
        number = $1.to_i
        parse_event(number, :type => number, :params => $')
      
      when /^:(\S+)!(\S+)@(\S+) PRIVMSG #(\S+) :/
        parse_event(:channel, :type => :channel, :nick => $1, :user => $2, :host => $3, :channel => "##{$4}", :message => $')
      
      when /^:(\S+)!(\S+)@(\S+) PRIVMSG \S+ :/
        parse_event(:query, :type => :query, :nick => $1, :user => $2, :host => $3, :message => $')
      
      when /^:(\S+)!(\S+)@(\S+) JOIN :*(\S+)$/
        parse_event(:join, :type => :join, :nick => $1, :user => $2, :host => $3, :channel => $4)
      
      when /^:(\S+)!(\S+)@(\S+) PART (\S+)/
        parse_event(:part, :type => :part, :nick => $1, :user => $2, :host => $3, :channel => $4, :message => $'.sub(/ :/, ''))
      
      when /^:(\S+)!(\S+)@(\S+) QUIT/
        parse_event(:quit, :type => :quit, :nick => $1, :user => $2, :host => $3, :message => $'.sub(/ :/, ''))
      
      when /^:(\S+)!(\S+)@(\S+) NICK :/
        parse_event(:nickchange, :type => :nickchange, :nick => $1, :user => $2, :host => $3, :new_nick => $')
      
      when /^:(\S+)!(\S+)@(\S+) KICK (\S+) (\S+) :/
        parse_event(:kick, :type => :kick, :nick => $1, :user => $2, :host => $3, :channel => $4, :victim => $5, :reason => $')
      
      when /^:(\S+)!(\S+)@(\S+) TOPIC (\S+) :/
        parse_event(:topic, :type => :topic, :nick => $1, :user => $2, :host => $3, :channel => $4, :topic => $')
      end
      
      @observer_queues.each do |queue, regexps|
        regexps.each do |regexp|
          if message =~ regexp
            queue << message
          end
        end
      end
    end
    
    # process callbacks with its begin; rescue; end
    def process_callbacks(event_type, event_data)
      @callbacks[event_type].each do |callback|
        EM.defer(
          Proc.new do
            begin
              stop_running = false
              
              # before filters (specific filters first, then :all)
              (@before_filters[event_type] + @before_filters[:all]).each do |filter|
                if filter.call(event_type, event_data) == false
                  stop_running = true
                  break
                end
              end
              
              unless stop_running
                # handling
                callback.call(event_type, event_data)
                
                # after filters (specific filters first, then :all)
                (@after_filters[event_type] + @after_filters[:all]).each do |filter|
                  filter.call(event_type, event_data)
                end
              end
            rescue => e
              @error_logger.error(e.message, *e.backtrace)
              @console_logger.error(e.message, *e.backtrace)
            end
          end
        )
      end
    end
    
    def before_filter(event_types = :all, match = //, &block)
      filter(@before_filters, event_types, match, block)
    end
    
    def after_filter(event_types = :all, match = //, &block)
      filter(@after_filters, event_types, match, block)
    end
    
    private
    
    # parses incoming traffic (types)
    def parse_event(event_type, event_data = {})
      if ((event_type == 376) || (event_type == 422)) && !@connected
        @connected = true
        process_callbacks(:connect, event_data)
      end
      
      process_callbacks(event_type, event_data)
    end
    
    def filter(filter_type, event_types = :all, match = //, &block)
      if event_types.is_a?(Array)
        event_types.each do |event_type|
          filter_type[event_type] << Filter.new(event_type, match, block)
        end
      elsif
        filter_type[event_types] << Filter.new(event_types, match, block)
      end
    end
  end
end

