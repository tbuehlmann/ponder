$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))

require 'ponder'

# This Thaum will parrot all channel messages.
@ponder = Ponder::Thaum.new

@ponder.configure do |c|
  c.server    = 'chat.freenode.org'
  c.port      = 6667
  c.nick      = 'Ponder'
  c.verbose   = true
  c.logging   = false
end

@ponder.on :connect do
  @ponder.join '#ponder'
end

@ponder.on :channel, // do |event_data|
  @ponder.message event_data[:channel], event_data[:message]
end

@ponder.connect

