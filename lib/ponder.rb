$LOAD_PATH.unshift(File.dirname(__FILE__))

module Ponder
  ROOT = File.dirname($0)

  autoload :AsyncIRC, 'ponder/async_irc'
  autoload :Callback, 'ponder/callback'
  autoload :Connection, 'ponder/connection'
  autoload :Filter, 'ponder/filter'
  autoload :Formatting, 'ponder/formatting'
  autoload :IRC, 'ponder/irc'
  autoload :Thaum, 'ponder/thaum'
  autoload :VERSION, 'ponder/version'

  module Logger
    autoload :Twoflogger, 'ponder/logger/twoflogger'
    autoload :BlindIo, 'ponder/logger/blind_io'
  end
end

