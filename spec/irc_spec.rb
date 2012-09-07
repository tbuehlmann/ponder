$LOAD_PATH.unshift(File.dirname(__FILE__))

require 'spec_helper'
require 'ponder/thaum'

describe Ponder::IRC do
  before(:each) do
    @thaum = Ponder::Thaum.new do |t|
      t.nick      = 'Ponder'
      t.username  = 'Ponder'
      t.real_name = 'Ponder Stibbons'
      t.reconnect = true
    end
  end

  it 'sends a message to a recipient' do
    @thaum.should_receive(:raw).with('PRIVMSG recipient :foo bar baz').once
    @thaum.message('recipient', 'foo bar baz')
  end

  it 'registers with the server' do
    @thaum.should_receive(:raw).with('NICK Ponder').once
    @thaum.should_receive(:raw).with('USER Ponder * * :Ponder Stibbons').once
    @thaum.register
  end

  it 'registers with the server with a password' do
    @thaum = Ponder::Thaum.new do |t|
      t.nick      = 'Ponder'
      t.username  = 'Ponder'
      t.real_name = 'Ponder Stibbons'
      t.reconnect = true
      t.password  = 'secret'
    end
    @thaum.should_receive(:raw).with('NICK Ponder').once
    @thaum.should_receive(:raw).with('USER Ponder * * :Ponder Stibbons').once
    @thaum.should_receive(:raw).with('PASS secret').once
    @thaum.register
  end

  it 'sends a notice to a recipient' do
    @thaum.should_receive(:raw).with('NOTICE Ponder :You are cool!').once
    @thaum.notice('Ponder', 'You are cool!')
  end

  it 'sets a mode' do
    @thaum.should_receive(:raw).with('MODE Ponder +ao').once
    @thaum.mode('Ponder', '+ao')
  end

  it 'kicks an user from a channel' do
    @thaum.should_receive(:raw).with('KICK #channel Nanny_Ogg').once
    @thaum.kick('#channel', 'Nanny_Ogg')
  end

  it 'kicks an user from a channel with a reason' do
    @thaum.should_receive(:raw).with('KICK #channel Nanny_Ogg :Go away!').once
    @thaum.kick('#channel', 'Nanny_Ogg', 'Go away!')
  end

  it 'performs an action' do
    @thaum.should_receive(:raw).with("PRIVMSG #channel :\001ACTION HEX is working!\001").once
    @thaum.action('#channel', 'HEX is working!')
  end

  it 'sets the topic for a channel' do
    @thaum.should_receive(:raw).with('TOPIC #channel :I like dried frog pills.').once
    @thaum.topic('#channel', 'I like dried frog pills.')
  end

  it 'joins a channel' do
    @thaum.should_receive(:raw).with('JOIN #channel').once
    @thaum.join('#channel')
  end

  it 'joins a channel with password' do
    @thaum.should_receive(:raw).with('JOIN #channel secret').once
    @thaum.join('#channel', 'secret')
  end

  it 'parts a channel' do
    @thaum.should_receive(:raw).with('PART #channel').once
    @thaum.part('#channel')
  end

  it 'parts a channel with a message' do
    @thaum.should_receive(:raw).with('PART #channel :Partpart').once
    @thaum.part('#channel', 'Partpart')
  end

  it 'quits from the server' do
    @thaum.should_receive(:raw).with('QUIT').once
    @thaum.config.reconnect.should eql(true)
    @thaum.quit
    @thaum.config.reconnect.should eql(false)
  end

  it 'quits from the server with a message' do
    @thaum.should_receive(:raw).with('QUIT :Gone!').once
    @thaum.config.reconnect.should eql(true)
    @thaum.quit('Gone!')
    @thaum.config.reconnect.should eql(false)
  end

  it 'renames itself' do
    @thaum.should_receive(:raw).with('NICK :Ridcully').once
    @thaum.rename('Ridcully')
  end

  it 'goes away' do
    @thaum.should_receive(:raw).with('AWAY').once
    @thaum.away
  end

  it 'goes away with a reason' do
    @thaum.should_receive(:raw).with('AWAY :At the Mended Drum').once
    @thaum.away('At the Mended Drum')
  end

  it 'comes back from its absence' do
    @thaum.should_receive(:raw).with('AWAY').twice
    @thaum.away
    @thaum.back
  end

  it 'invites an user to a channel' do
    @thaum.should_receive(:raw).with('INVITE TheLibrarian #mended_drum').once
    @thaum.invite('TheLibrarian', '#mended_drum')
  end

  it 'bans an user from a channel' do
    @thaum.should_receive(:raw).with('MODE #mended_drum +b foo!bar@baz').once
    @thaum.ban('#mended_drum', 'foo!bar@baz')
  end
end
