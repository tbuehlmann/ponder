$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))

require 'ponder'

# This Thaum will parrot all channel messages.
@thaum = Ponder::Thaum.new do |config|
  config.server  = 'chat.freenode.org'
  config.port    = 6667
  config.nick    = 'Ponder'
end

@thaum.on :connect do
  @thaum.join '#ponder'
end

@thaum.on :channel, // do |event_data|
  @thaum.message event_data[:channel], event_data[:message]
end

@thaum.connect
