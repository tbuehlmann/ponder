require 'fiber'
require 'fileutils'
require 'logger'
require 'ostruct'
require 'set'
require 'thread'

require 'eventmachine'

require 'core_ext/array'

module Ponder
  require 'ponder/callback'
  require 'ponder/recipient'
  require 'ponder/channel'
  require 'ponder/channel_list'
  require 'ponder/connection'
  require 'ponder/formatting'
  require 'ponder/irc'
  require 'ponder/isupport'
  require 'ponder/thaum'
  require 'ponder/user'
  require 'ponder/user_list'
  require 'ponder/version'

  module IRC
    module Events
      require 'ponder/irc/events/channel_mode'
      require 'ponder/irc/events/join'
      require 'ponder/irc/events/kick'
      require 'ponder/irc/events/message'
      require 'ponder/irc/events/mode_parser'
      require 'ponder/irc/events/parser'
      require 'ponder/irc/events/part'
      require 'ponder/irc/events/quit'
    end
  end

  module Logging
    require 'ponder/logging/blind_io'
    require 'ponder/logging/logger_list'
    require 'ponder/logging/twoflogger'
  end
end
