module Ponder
  # Data structure which is used for storing users:
  # {lower_cased_nick => {User => [modes]}}
  #
  # Example:
  # {'ponder' => {:user => #<User nick="Ponder">, :modes => ['v', 'o']}}
  class Channel < Recipient
    attr_reader :name, :users, :users_with_modes, :modes, :lists
    attr_accessor :created_at

    def initialize(name, thaum)
      super
      @name = name
      @users = Set.new
      @users_with_modes = {}
      @modes = {}
      @lists = Hash.new { |hash, key| hash[key] = [] }
    end

    # Experimental, no tests so far.
    def topic
      if @topic
        @topic
      else
        fiber = Fiber.current
        callbacks = {}
        [331, 332, 403, 442].each do |numeric|
          callbacks[numeric] = @thaum.on(numeric) do |event_data|
            topic = event_data[:params].match(':(.*)').captures.first
            fiber.resume topic
          end
        end

        raw "TOPIC #{@name}"
        @topic = Fiber.yield
        callbacks.each do |type, callback|
          @thaum.callbacks[type].delete(callback)
        end

        @topic
      end
    end

    def topic=(topic)
      raw "TOPIC #{@name} :#{topic}"
    end

    def ban(hostmask)
      mode '+b', hostmask
    end

    def unban(hostmask)
      mode '-b', hostmask
    end

    def lock(key)
      raw "MODE #{@name} +k #{key}"
    end

    def unlock
      key = @modes['k']
      raw "MODE #{@name} -k #{key}" if key
    end

    def kick(user_or_nick, reason = nil)
      nick = user_or_nick_to_nick(user_or_nick)

      if reason
        raw "KICK #{@name} #{nick} :#{reason}"
      else
        raw "KICK #{@name} #{nick}"
      end
    end

    def invite(user_or_nick)
      nick = user_or_nick_to_nick(user_or_nick)
      raw "INVITE #{@name} #{nick}"
    end

    def op(user_or_nick)
      nick = user_or_nick_to_nick(nick)
      mode '+o', nick
    end

    def deop(user_or_nick)
      nick = user_or_nick_to_nick(nick)
      mode '-o', nick
    end

    def voice(user_or_nick)
      nick = user_or_nick_to_nick(nick)
      mode '+v', nick
    end

    def devoice(user_or_nick)
      nick = user_or_nick_to_nick(nick)
      mode '-v', nick
    end

    def join(key = nil)
      if key
        raw "JOIN #{@name} #{key}"
      else
        raw "JOIN #{@name}"
      end
    end

    def part(message = nil)
      if message
        raw "PART #{@name} :#{message}"
      else
        raw "PART #{@name}"
      end
    end

    def hop(message = nil)
      key = @modes['k']
      part message
      join key
    end

    def add_user(user, modes = [])
      synchronize do
        @users << user
        @users_with_modes[user] = modes
      end
    end

    def remove_user(user_or_nick)
      synchronize do
        if user_or_nick.is_a?(String)
          user = find_user(user_or_nick)
        end

        @users_with_modes.delete(user)
        @users.delete?(user) ? user : nil
      end
    end

    def has_user?(user_or_nick)
      case user_or_nick
      when String
        find_user(user_or_nick) ? true : false
      when User
        @users.include? user_or_nick
      end
    end

    def find_user(user_or_nick)
      case user_or_nick
      when String
        @users.find { |u| u.nick.downcase == user_or_nick.downcase }
      when User
        has_user?(user_or_nick) ? user_or_nick : nil
      end
    end

    def find_user_with_modes(user_or_nick)
      user = case user_or_nick
      when String
        @users.find { |u| u.nick.downcase == user_or_nick.downcase }
      when User
        has_user?(user_or_nick) ? user_or_nick : nil
      end

      {:user => user, :modes => @users_with_modes[user]} if user
    end

    def modes_of(user_or_nick)
      user = find_user(user_or_nick)
      @users_with_modes[user] if user
    end

    def set_mode(mode, isupport)
      if isupport['PREFIX'].keys.include?(mode.mode)
        user = find_user(mode.param)
        if user
          case mode.direction 
          when :'+'
            @users_with_modes[user] << mode.mode
          when :'-'
            @users_with_modes[user].delete mode.mode
          end
        end
      elsif isupport['CHANMODES']['A'].include?(mode.mode)
        case mode.direction 
        when :'+'
          add_to_list(mode.mode, mode.param)
        when :'-'
          remove_from_list(mode.mode, mode.param)
        end
      elsif isupport['CHANMODES']['B'].include?(mode.mode)
        case mode.direction 
        when :'+'
          set_channel_mode(mode.mode, mode.param)
        when :'-'
          unset_channel_mode mode.mode
        end
      elsif isupport['CHANMODES']['C'].include?(mode.mode)
        case mode.direction 
        when :'+'
          set_channel_mode(mode.mode, mode.param)
        when :'-'
          unset_channel_mode mode.mode
        end
      elsif isupport['CHANMODES']['D'].include?(mode.mode)
        case mode.direction 
        when :'+'
          set_channel_mode(mode.mode, true)
        when :'-'
          unset_channel_mode mode.mode
        end
      end
    end

    def mode(modes, params = nil)
      if params
        raw "MODE #{@name} #{modes} #{params}"
      else
        raw "MODE #{@name} #{modes}"
      end
    end

    def get_mode
      raw "MODE #{@name}"
    end

    def message(message)
      raw "PRIVMSG #{@name} :#{message}"
    end

    def inspect
      "#<Channel name=#{@name.inspect}>"
    end

    private

    def set_channel_mode(mode, param)
      synchronize { @modes[mode] = param }
    end

    def unset_channel_mode(mode)
      synchronize { @modes.delete(mode) }
    end

    def add_to_list(list, param)
      synchronize do
        @lists[list] ||= []
        @lists[list] << param
      end
    end

    def remove_from_list(list, param)
      synchronize do
        if @lists[list].include? param
          @lists[list].delete param
        end
      end
    end

    def user_or_nick_to_nick(user_or_nick)
      if user_or_nick.respond_to? :nick
        user_or_nick.nick
      else
        user_or_nick
      end
    end
  end
end
