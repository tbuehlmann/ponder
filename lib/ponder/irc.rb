module Ponder
  module IRC
    # raw IRC messages
    def raw(message)
      @connection.send_data "#{message}\r\n"
      @traffic_logger.info ">> #{message}"
      @console_logger.info ">> #{message}"
    end
    
    # send a message
    def message(recipient, message)
      raw "PRIVMSG #{recipient} :#{message}"
    end
    
    def register
      raw "NICK #{@config.nick}"
      raw "USER #{@config.nick} 0 * :#{@config.realname}"
      raw "PASS #{@config.password}" if @config.password
    end
    
    # send a notice
    def notice(recipient, message)
      raw "NOTICE #{recipient} :#{message}"
    end
    
    # set a mode
    def mode(recipient, option)
      raw "MODE #{recipient} #{option}"
    end
    
    # kick a user
    def kick(channel, user, reason = nil)
      if reason
        raw "KICK #{channel} #{user} :#{reason}"
      else
        raw "KICK #{channel} #{user}"
      end
    end
    
    # perform an action
    def action(recipient, message)
      raw "PRIVMSG #{recipient} :\001ACTION #{message}\001"
    end
    
    # set a topic
    def topic(channel, topic)
      raw "TOPIC #{channel} :#{topic}"
    end
    
    # joining a channel
    def join(channel, password = nil)
      if password
        raw "JOIN #{channel} #{password}"
      else
        raw "JOIN #{channel}"
      end
    end
    
    # parting a channel
    def part(channel, message = nil)
      if message
        raw "PART #{channel} :#{message}"
      else
        raw "PART #{channel}"
      end
    end
    
    # quitting
    def quit(message = nil)
      if message
        raw "QUIT :#{message}"
      else
        raw 'QUIT'
      end
      
      @config.reconnect = false # so Ponder does not reconnect after the socket has been closed
    end
    
    def rename(nick)
      raw "NICK :#{nick}"
    end
    
    def away(message = nil)
      if message
        raw "AWAY :#{message}"
      else
        raw "AWAY"
      end
    end
    
    def back
      away
    end
  end
end
