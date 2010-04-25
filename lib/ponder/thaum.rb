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
    end
    
    def configure(&block)
      unless @reloading
        block.call(@config)
        
        # logger
        if @config.logging
          @traffic_logger = TwoFlogger.new(PONDER_ROOT.join('logs').expand_path, 'traffic.log')
          @error_logger   = TwoFlogger.new(PONDER_ROOT.join('logs').expand_path, 'error.log')
        end
      end
    end
    
    def on(type = [:channel], match = //, &block)
      if type.is_a?(Array)
        callbacks = type.map { |t| Callback.new(t, match, block) }
      else
        callbacks = [Callback.new(type, match, block)]
      end
      
      callbacks.each do |callback|
        @callbacks[callback.type] << callback
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
      @traffic_logger.info("<< #{message.chomp}") if @traffic_logger
      puts "#{Time.now.strftime('%d.%m.%Y %H:%M:%S')} << #{message.chomp}" if @config.verbose
      
      case message.chomp
      when /^PING \S+$/
        raw message.chomp.gsub('PING', 'PONG')
      
      when /^:\S+ (\d\d\d) /
        parse_type($1, :type => $1.to_sym, :params => $')
      
      when /^:(\S+)!(\S+)@(\S+) PRIVMSG #(\S+) :/
        parse_type(:channel, :type => :channel, :nick => $1, :user => $2, :host => $3, :channel => "##{$4}", :message => $')
      
      when /^:(\S+)!(\S+)@(\S+) PRIVMSG \S+ :/
        parse_type(:query, :type => :query, :nick => $1, :user => $2, :host => $3, :message => $')
      
      when /^:(\S+)!(\S+)@(\S+) JOIN :*(\S+)$/
        parse_type(:join, :type => :join, :nick => $1, :user => $2, :host => $3, :channel => $4)
      
      when /^:(\S+)!(\S+)@(\S+) PART (\S+)/
        parse_type(:part, :type => :part, :nick => $1, :user => $2, :host => $3, :channel => $4, :message => $'.sub(' :', ''))
      
      when /^:(\S+)!(\S+)@(\S+) QUIT/
        parse_type(:quit, :type => :quit, :nick => $1, :user => $2, :host => $3, :message => $'.sub(' :', ''))
      
      when /^:(\S+)!(\S+)@(\S+) NICK :/
        parse_type(:nickchange, :type => :nickchange, :nick => $1, :user => $2, :host => $3, :new_nick => $')
      
      when /^:(\S+)!(\S+)@(\S+) KICK (\S+) (\S+) :/
        parse_type(:kick, :type => :kick, :nick => $1, :user => $2, :host => $3, :channel => $4, :victim => $5, :reason => $')
      end
      
      if @observers > 0
        @temp_socket << message.chomp
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
    def parse_type(type, env = {})
      case type
      # :connect
      when /^376|422$/
        unless @connected
          @connected = true
          call_callbacks(:connect, env)
        end
      when :query
        # version response
        if env[:message] == "\001VERSION\001"
          notice env[:nick], "\001VERSION #{VERSION}\001"
        end
        
        # time response
        if env[:message] == "\001TIME\001"
          notice env[:nick], "\001TIME #{Time.now.strftime('%a %b %d %H:%M:%S %Y')}\001"
        end
        
        # ping response
        if env[:message] =~ /\001PING (\d+)\001/
          notice env[:nick], "\001PING #{$1}\001"
        end
        call_callbacks(type, env)
      else
        call_callbacks(type, env)
      end
    end
    
    # calls callbacks with its begin; rescue; end
    def call_callbacks(type, env)
      @callbacks[type].each do |callback|
        EM.defer(
          Proc.new do
            begin
              callback.call(type, env)
            rescue => e
              @error_logger.error(e.message, *e.backtrace) if @error_logger
            end
          end
        )
      end
    end
  end
end
