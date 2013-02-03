$LOAD_PATH.unshift(File.dirname(__FILE__))

module Ponder
  ROOT = File.dirname($0)

  autoload :AsyncIRC, 'ponder/async_irc'
  autoload :Callback, 'ponder/callback'
  autoload :Channel, 'ponder/channel'
  autoload :ChannelList, 'ponder/channel_list'
  autoload :Connection, 'ponder/connection'
  autoload :Event, 'ponder/event'
  autoload :Filter, 'ponder/filter'
  autoload :Formatting, 'ponder/formatting'
  autoload :IRC, 'ponder/irc'
  autoload :Thaum, 'ponder/thaum'
  autoload :User, 'ponder/user'
  autoload :UserList, 'ponder/user_list'
  autoload :VERSION, 'ponder/version'

  module IRC
    module Events
      autoload :ChannelMode, 'ponder/irc/events/channel_mode'
      autoload :Join, 'ponder/irc/events/join'
      autoload :Kick, 'ponder/irc/events/kick'
      autoload :Message, 'ponder/irc/events/message'
      autoload :ModeParser, 'ponder/irc/events/mode_parser'
      autoload :Parser, 'ponder/irc/events/parser'
      autoload :Part, 'ponder/irc/events/part'
      autoload :Quit, 'ponder/irc/events/quit'
    end
  end

  module Logging
    autoload :Twoflogger, 'ponder/logging/twoflogger'
    autoload :BlindIo, 'ponder/logging/blind_io'
    autoload :LoggerList, 'ponder/logging/logger_list'
  end
end
