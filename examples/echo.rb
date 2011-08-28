$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))

require 'ponder'

# This Thaum will parrot all channel messages.
@ponder = Ponder::Thaum.new do |t|
  t.server    = 'chat.freenode.org'
  t.port      = 6667
  t.nick      = 'Ponder'
  t.verbose   = true
  t.logging   = false
end

@ponder.on :connect do
  @ponder.join '#ponder'
end

@ponder.on :channel, // do |event_data|
  @ponder.message event_data[:channel], event_data[:message]
end

@ponder.connect

