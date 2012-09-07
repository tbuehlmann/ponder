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

  module Logger
    autoload :Twoflogger, 'ponder/logger/twoflogger'
    autoload :BlindIo, 'ponder/logger/blind_io'
  end
end
