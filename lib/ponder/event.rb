module Ponder
  class Event < Hash
    class << self
      def parse(message, chantypes)
        result_hash = case message
        when /^(?:\:\S+ )?(\d\d\d) /
          number = $1.to_i
          {:type => number, :params => $'}
        when /^:(\S+)!(\S+)@(\S+) PRIVMSG ((?:#{chantypes.join('|')})\S+) :/
          {:type => :channel, :nick => $1, :user => $2, :host => $3, :channel => $4, :message => $'}
        when /^:(\S+)!(\S+)@(\S+) PRIVMSG \S+ :/
          {:type => :query, :nick => $1, :user => $2, :host => $3, :message => $'}
        when /^:(\S+)!(\S+)@(\S+) JOIN :*(\S+)$/
          {:type => :join, :nick => $1, :user => $2, :host => $3, :channel => $4}
        when /^:(\S+)!(\S+)@(\S+) PART (\S+)/
          {:type => :part, :nick => $1, :user => $2, :host => $3, :channel => $4, :message => $'.sub(/ :/, '')}
        when /^:(\S+)!(\S+)@(\S+) QUIT/
          {:type => :quit, :nick => $1, :user => $2, :host => $3, :message => $'.sub(/ :/, '')}
        when /^:(\S+)!(\S+)@(\S+) NICK :/
          {:type => :nickchange, :nick => $1, :user => $2, :host => $3, :new_nick => $'}
        when /^:(\S+)!(\S+)@(\S+) KICK (\S+) (\S+) :/
          {:type => :kick, :nick => $1, :user => $2, :host => $3, :channel => $4, :victim => $5, :reason => $'}
        when /^:(\S+)!(\S+)@(\S+) TOPIC (\S+) :/
          {:type => :topic, :nick => $1, :user => $2, :host => $3, :channel => $4, :topic => $'}
        else
          nil
        end

        if result_hash
          new.merge(result_hash)
        else
          new
        end
      end
    end
  end
end
