$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))

require 'ponder'

# This Thaum will parrot all channel messages.
@thaum = Ponder::Thaum.new do |t|
  t.server    = 'chat.freenode.org'
  t.port      = 6667
  t.nick      = 'Ponder'
  t.verbose   = true
  t.logging   = false
end

@thaum.on :connect do
  @thaum.join '#ponder'
end

@thaum.on :channel, // do |event_data|
  @thaum.message event_data[:channel], event_data[:message]
end

@thaum.connect
