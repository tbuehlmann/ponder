module Ponder
  class Thaum
    include IRC

    attr_reader :config, :callbacks, :isupport, :channel_list, :user_list, :connection, :loggers
    attr_accessor :connected, :deferrables

    def initialize(&block)
      # default settings
      @config = OpenStruct.new(
        :server             => 'chat.freenode.org',
        :port               => 6667,
        :ssl                => false,
        :nick               => "Ponder#{rand(10_000)}",
        :username           => 'Ponder',
        :real_name          => 'Ponder Stibbons',
        :verbose            => true,
        :logging            => false,
        :reconnect          => true,
        :reconnect_interval => 30,
        :hide_ping_pongs    => true
      )

      # custom settings
      block.call(@config) if block_given?

      # setting up loggers
      @console_logger = if @config.verbose
        Logging::Twoflogger.new($stdout)
      else
        Logging::BlindIo.new
      end

      @logger = if @config.logging
        if @config.logger
          @config.logger
        else
          log_path = File.join($0, 'logs', 'log.log')
          log_dir = File.dirname(log_path)
          FileUtils.mkdir_p(log_dir) unless File.exist?(log_dir)
          Logging::Twoflogger.new(log_path, File::WRONLY | File::APPEND)
        end
      else
        Logging::BlindIo.new
      end

      @loggers = Logging::LoggerList.new
      @loggers.push(@console_logger, @logger)

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
      @loggers.info '-- Starting Ponder'

      EventMachine::run do
        @connection = EventMachine::connect(@config.server, @config.port, Connection, self)
      end
    end

    # parsing incoming traffic
    def parse(message)
      message.chomp!

      if message =~ /^PING \S+$/
        if @config.hide_ping_pongs
          send_data message.sub(/PING/, 'PONG')
        else
          @loggers.info "<< #{message}"
          raw message.sub(/PING/, 'PONG')
        end
      else
        @loggers.info "<< #{message}"
        event_data = IRC::Events::Parser.parse(message, @isupport['CHANTYPES'])
        parse_event_data(event_data) unless event_data.empty?
      end
    end

    # Each matching callback will run in its own fiber. So the execution
    # of code can be stopped until necessary data (eg from a WHOIS) gets in.
    #
    # The callback processing is exception handled, so the EM reactor won't die
    # from exceptions.
    def process_callbacks(event_type, event_data)
      @callbacks[event_type].each do |callback|
        fiber = Fiber.new do
          begin
            callback.call(event_data)
          rescue => e
            @loggers.error "-- #{e.class}: #{e.message}"
            e.backtrace.each { |line| @loggers.error("-- #{line}") }
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
    def parse_event_data(event_data)
      if ((event_data[:type] == 376) || (event_data[:type] == 422)) && !@connected
        @connected = true
        process_callbacks(:connect, event_data)
      end

      process_callbacks(event_data[:type], event_data)
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
        joined_user = {
          :nick => event_data.delete(:nick),
          :user => event_data.delete(:user),
          :host => event_data.delete(:host)
        }
        channel = event_data.delete(:channel)

        # TODO: Update existing users with user/host information.

        # Refactor
        user = @user_list.find(joined_user[:nick])
        if user
          if user.thaum?
            channel = Channel.new(channel, self)
            channel.get_mode
            @channel_list.add channel
          else
            channel = @channel_list.find(channel)
          end
        else
          channel = @channel_list.find(channel)
          user = User.new(joined_user[:nick], self)
          @user_list.add user
        end

        channel.add_user(user, [])
        event_data[:join] = IRC::Events::Join.new(user, channel)
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
        nick    = event_data.delete(:nick)
        user    = event_data.delete(:user)
        host    = event_data.delete(:host)
        channel = event_data.delete(:channel)
        message = event_data.delete(:message)

        # TODO: Update existing users with user/host information.

        user = @user_list.find(nick)
        channel = @channel_list.find(channel)
        if user.thaum?
          # Remove the channel from the channel_list.
          @channel_list.remove(channel)

          # Remove all users from the user_list that do not share channels
          # with the Thaum.
          all_known_users = @channel_list.channels.map(&:users).flatten
          @user_list.kill_zombie_users(all_known_users)
        else
          channel.remove_user nick
          remove_user = @channel_list.channels.none? do |_channel|
            _channel.has_user? nick
          end

          @user_list.remove(nick) if remove_user
        end

        event_data[:part] = IRC::Events::Part.new(user, channel, message)
      end

      # TODO: Kick object!
      # :kicker!foo@bar KICK #channel gekickter :reason
      on :kick do |event_data|
        nick    = event_data.delete(:nick)
        user    = event_data.delete(:user)
        host    = event_data.delete(:host)
        channel = event_data.delete(:channel)
        victim  = event_data.delete(:victim)
        message = event_data.delete(:message)

        channel = @channel_list.find(channel)
        kicker = @user_list.find(nick)
        victim = @user_list.find(victim)

        channel.remove_user victim.nick

        if victim.thaum?
          # Remove the channel from the channel_list.
          @channel_list.remove(channel)

          # Remove all users from the user_list that do not share channels
          # with the Thaum.
          all_known_users = @channel_list.channels.map(&:users).flatten
          @user_list.kill_zombie_users(all_known_users)
        else
          remove_user = @channel_list.channels.none? do |_channel|
            _channel.has_user?(victim)
          end

          @user_list.remove(victim.nick) if remove_user
        end

        event_data[:kick] = Ponder::IRC::Events::Kick.new(kicker, victim, channel, message)
      end

      on :quit do |event_data|
        nick    = event_data.delete(:nick)
        user    = event_data.delete(:user)
        host    = event_data.delete(:host)
        message = event_data.delete(:message)

        # TODO: Update existing users with user/host information.

        user = @user_list.find nick

        if user.thaum?
          channels = @channel_list.clear
          @user_list.clear
        else
          channels = @channel_list.remove_user(nick)
          @user_list.remove nick
        end

        event_data[:quit] = IRC::Events::Quit.new(user, channels, message)
      end

      on :disconnect do |event_data|
        @channel_list.clear
        @user_list.clear
      end

      on :channel do |event_data|
        nick    = event_data[:nick]
        user    = event_data[:user]
        host    = event_data[:host]
        channel = event_data[:channel]
        message = event_data[:message]

        channel = @channel_list.find channel
        user = @user_list.find nick
        # TODO: Update existing users with user/host information.

        event_data[:message] = IRC::Events::Message.new(user, message, channel)
      end

      on :query do |event_data|
        nick    = event_data[:nick]
        user    = event_data[:user]
        host    = event_data[:host]
        message = event_data[:message]

        user = @user_list.find nick
        # TODO: Update existing users with user/host information.

        event_data[:message] = IRC::Events::Message.new(user, message)
      end

      on :channel_mode do |event_data|
        # TODO: Update existing users with user/host information.
        # nick = event_data[:nick]
        # user = event_data[:user]
        # host = event_data[:host]

        channel = event_data.delete(:channel)
        nick    = event_data.delete(:nick)
        params  = event_data.delete(:params)
        modes   = event_data.delete(:modes)

        channel = @channel_list.find(channel)
        event_data[:channel] = channel
        event_data[:user]    = @user_list.find(nick)

        mode_changes = IRC::Events::ModeParser.parse(modes, params, @isupport)
        event_data[:channel_modes] = mode_changes.map do |mode_change|
          IRC::Events::ChannelMode.new(mode_change.merge(:channel => channel))
        end

        event_data[:channel_modes].each do |mode|
          channel.set_mode(mode, isupport)
        end
      end

      # Response to MODE command, giving back the channel modes.
      on 324 do |event_data|
        split = event_data[:params].split(/ /)
        channel_name = split[1]
        channel = @channel_list.find(channel_name)

        if channel
          modes = split[2]
          params = split[3..-1]

          mode_changes = IRC::Events::ModeParser.parse(modes, params, @isupport)
          channel_modes = mode_changes.map do |mode_change|
            IRC::Events::ChannelMode.new(mode_change.merge(:channel => channel))
          end

          channel_modes.each do |mode|
            channel.set_mode(mode, isupport)
          end
        end
      end

      # Response to MODE command, giving back the time,
      # the channel was created.
      on 329 do |event_data|
        split = event_data[:params].split(/ /)
        channel_name = split[1]
        channel = @channel_list.find(channel_name)

        # Only set created_at if the Thaum is on the channel.
        if channel
          epoch_time = split[2].to_i
          channel.created_at = Time.at(epoch_time)
        end
      end
    end
  end
end
