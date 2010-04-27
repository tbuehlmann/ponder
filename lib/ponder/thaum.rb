require 'ponder/callback'
require 'ponder/connection'
require 'ponder/irc'
require 'ponder/delegate'
require 'ostruct'
Ponder.autoload :'TwoFlogger', 'ponder/two_flogger.rb'

module Ponder
  class Thaum
    include Delegate, IRC
    
    attr_reader :config
    attr_accessor :connected, :traffic_logger
    
    def initialize
      @config = OpenStruct.new(:server             => 'localhost',
                               :port               => 6667,
                               :nick               => 'Ponder',
                               :realname           => 'Ponder',
                               :verbose            => true,
                               :logging            => false,
                               :reconnect          => true,
                               :reconnect_interval => 30
                              )
      
      @observers = 0
      @temp_socket = []
      
      @connected = false
      @reloading = false
      
      # user callbacks
      @callbacks = Hash.new { |hash, key| hash[key] = [] } ## old: Hash.new []
      
      # observer synchronizer
      @mutex_observer = Mutex.new
      
      # standard callbacks for PING, VERSION and TIME
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
    end
    
    def configure(&block)
      unless @reloading
        block.call(@config)
        
        # logger
        if @config.logging
          @traffic_logger = TwoFlogger.new(Ponder.root.join('logs').expand_path, 'traffic.log')
          @error_logger   = TwoFlogger.new(Ponder.root.join('logs').expand_path, 'error.log')
        end
      end
    end
    
    def on(event_types = [:channel], match = //, &block)
      if event_types.is_a?(Array)
        callbacks = event_types.map { |event_type| Callback.new(self, event_type, match, block) }
      else
        callbacks = [Callback.new(self, event_types, match, block)]
      end
      
      callbacks.each do |callback|
        @callbacks[callback.event_type] << callback
      end
    end
    
    def connect(run = true)
      unless @reloading
        @traffic_logger.info('-- Starting Ponder') if @traffic_logger
        puts "#{Time.now.strftime('%d.%m.%Y %H:%M:%S')} -- Starting Ponder"
        
        if run
          EventMachine::run do
            @connection = EventMachine::connect(@config.server, @config.port, Connection, self)
          end
        else
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
      @traffic_logger.info("<< #{message}") if @traffic_logger
      puts "#{Time.now.strftime('%d.%m.%Y %H:%M:%S')} << #{message}" if @config.verbose
      
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
        parse_event(:part, :type => :part, :nick => $1, :user => $2, :host => $3, :channel => $4, :message => $'.sub(' :', ''))
      
      when /^:(\S+)!(\S+)@(\S+) QUIT/
        parse_event(:quit, :type => :quit, :nick => $1, :user => $2, :host => $3, :message => $'.sub(' :', ''))
      
      when /^:(\S+)!(\S+)@(\S+) NICK :/
        parse_event(:nickchange, :type => :nickchange, :nick => $1, :user => $2, :host => $3, :new_nick => $')
      
      when /^:(\S+)!(\S+)@(\S+) KICK (\S+) (\S+) :/
        parse_event(:kick, :type => :kick, :nick => $1, :user => $2, :host => $3, :channel => $4, :victim => $5, :reason => $')
      end
      
      if @observers > 0
        @temp_socket << message
      end
    end
    
    private
    
    # add observer
    def add_observer
      @mutex_observer.synchronize do
        @observers += 1
      end
      
      return @temp_socket.length - 1 # so the loop knows where to begin to search for patterns
    end
    
    # remove observer
    def remove_observer
      @mutex_observer.synchronize do
        @observers -= 1 # remove observer
        @temp_socket.clear if @observers == 0 # clear @temp_socket if no observers are active
      end
    end
    
    # parses incoming traffic (types)
    def parse_event(event_type, event_data = {})
      if ((event_type == 376) || (event_type == 422)) && !@connected
        @connected = true
        process_callbacks(:connect, event_data)
      end
      
      process_callbacks(event_type, event_data)
    end
    
    # process callbacks with its begin; rescue; end
    def process_callbacks(event_type, event_data)
      @callbacks[event_type].each do |callback|
        EM.defer(
          Proc.new do
            begin
              callback.call(event_type, event_data)
            rescue => e
              @error_logger.error(e.message, *e.backtrace) if @error_logger
            end
          end
        )
      end
    end
  end
end
