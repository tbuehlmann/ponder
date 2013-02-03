module Ponder
  module IRC
    module Events
      module Parser
        def parse(message, chantypes)
          case message
          when /^(?:\:\S+ )?(\d\d\d) /
            number = $1.to_i
            {:type => number, :params => $'}
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
          when /^:(\S+)!(\S+)@(\S+) MODE ((?:#{chantypes.join('|')})\S+) ([+-]\S+)/
            {:type => :channel_mode, :nick => $1, :user => $2, :host => $3, :channel => $4, :modes => $5, :params => $'.lstrip}
          when /^:(\S+)!(\S+)@(\S+) NICK :/
            {:type => :nickchange, :nick => $1, :user => $2, :host => $3, :new_nick => $'}
          when /^:(\S+)!(\S+)@(\S+) KICK (\S+) (\S+) :/
            {:type => :kick, :nick => $1, :user => $2, :host => $3, :channel => $4, :victim => $5, :message => $'}
          when /^:(\S+)!(\S+)@(\S+) TOPIC (\S+) :/
            {:type => :topic, :nick => $1, :user => $2, :host => $3, :channel => $4, :topic => $'}
          else
            {}
          end
        end
        module_function :parse
      end
    end
  end
end
