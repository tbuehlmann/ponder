$LOAD_PATH.unshift(File.dirname(__FILE__))

require 'spec_helper'
require 'ponder/thaum'

describe Ponder::IRC do
  before(:each) do
    @ponder = Ponder::Thaum.new
    @ponder.configure do |c|
      c.nick      = 'Ponder'
      c.username  = 'Ponder'
      c.real_name = 'Ponder Stibbons'
      c.reconnect = true
    end
  end

  it 'sends a message to a recipient' do
    @ponder.should_receive(:raw).with('PRIVMSG recipient :foo bar baz').once
    @ponder.message('recipient', 'foo bar baz')
  end

  it 'registers with the server' do
    @ponder.should_receive(:raw).with('NICK Ponder').once
    @ponder.should_receive(:raw).with('USER Ponder * * :Ponder Stibbons').once
    @ponder.register
  end

  it 'registers with the server with a password' do
    @ponder.should_receive(:raw).with('NICK Ponder').once
    @ponder.should_receive(:raw).with('USER Ponder * * :Ponder Stibbons').once
    @ponder.should_receive(:raw).with('PASS secret').once
    @ponder.configure { |c| c.password = 'secret' }
    @ponder.register
  end

  it 'sends a notice to a recipient' do
    @ponder.should_receive(:raw).with('NOTICE Ponder :You are cool!').once
    @ponder.notice('Ponder', 'You are cool!')
  end

  it 'sets a mode' do
    @ponder.should_receive(:raw).with('MODE Ponder +ao').once
    @ponder.mode('Ponder', '+ao')
  end

  it 'kicks an user from a channel' do
    @ponder.should_receive(:raw).with('KICK #channel Nanny_Ogg').once
    @ponder.kick('#channel', 'Nanny_Ogg')
  end

  it 'kicks an user from a channel with a reason' do
    @ponder.should_receive(:raw).with('KICK #channel Nanny_Ogg :Go away!').once
    @ponder.kick('#channel', 'Nanny_Ogg', 'Go away!')
  end

  it 'performs an action' do
    @ponder.should_receive(:raw).with("PRIVMSG #channel :\001ACTION HEX is working!\001").once
    @ponder.action('#channel', 'HEX is working!')
  end

  it 'sets the topic for a channel' do
    @ponder.should_receive(:raw).with('TOPIC #channel :I like dried frog pills.').once
    @ponder.topic('#channel', 'I like dried frog pills.')
  end

  it 'joins a channel' do
    @ponder.should_receive(:raw).with('JOIN #channel').once
    @ponder.join('#channel')
  end

  it 'joins a channel with password' do
    @ponder.should_receive(:raw).with('JOIN #channel secret').once
    @ponder.join('#channel', 'secret')
  end

  it 'parts a channel' do
    @ponder.should_receive(:raw).with('PART #channel').once
    @ponder.part('#channel')
  end

  it 'parts a channel with a message' do
    @ponder.should_receive(:raw).with('PART #channel :Partpart').once
    @ponder.part('#channel', 'Partpart')
  end

  it 'quits from the server' do
    @ponder.should_receive(:raw).with('QUIT').once
    @ponder.config.reconnect.should eql(true)
    @ponder.quit
    @ponder.config.reconnect.should eql(false)
  end

  it 'quits from the server with a message' do
    @ponder.should_receive(:raw).with('QUIT :Gone!').once
    @ponder.config.reconnect.should eql(true)
    @ponder.quit('Gone!')
    @ponder.config.reconnect.should eql(false)
  end

  it 'renames itself' do
    @ponder.should_receive(:raw).with('NICK :Ridcully').once
    @ponder.rename('Ridcully')
  end

  it 'goes away' do
    @ponder.should_receive(:raw).with('AWAY').once
    @ponder.away
  end

  it 'goes away with a reason' do
    @ponder.should_receive(:raw).with('AWAY :At the Mended Drum').once
    @ponder.away('At the Mended Drum')
  end

  it 'comes back from its absence' do
    @ponder.should_receive(:raw).with('AWAY').twice
    @ponder.away
    @ponder.back
  end

  it 'invites an user to a channel' do
    @ponder.should_receive(:raw).with('INVITE TheLibrarian #mended_drum').once
    @ponder.invite('TheLibrarian', '#mended_drum')
  end

  it 'bans an user from a channel' do
    @ponder.should_receive(:raw).with('MODE #mended_drum +b foo!bar@baz').once
    @ponder.ban('#mended_drum', 'foo!bar@baz')
  end
end

