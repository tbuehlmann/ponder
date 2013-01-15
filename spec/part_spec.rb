$LOAD_PATH.unshift(File.dirname(__FILE__))

require 'spec_helper'
require 'ponder/thaum'

describe Ponder::IRC::Events::Part do
  before(:each) do
    @thaum = Ponder::Thaum.new do |config|
      config.nick = 'Ponder'
      config.verbose = false
    end

    # Connected to a server and joined #mended_drum.
    @thaum.parse ':server 376 Ponder :End of /MOTD command.'
    @thaum.parse ':Ponder!foo@bar JOIN #mended_drum'
  end

  it 'is correctly created when the Thaum parts a channel' do
    thaum_user = @thaum.user_list.find(@thaum.config.nick)
    channel = @thaum.channel_list.find('#mended_drum')

    @thaum.on :part do |event_data|
      expect(event_data[:part]).to be_kind_of Ponder::IRC::Events::Part
      expect(event_data[:part].user).to eql(thaum_user)
      expect(event_data[:part].channel).to eql(channel)
      expect(event_data[:part].message).to eql('Bye!')
      @called = true
    end
    
    @thaum.parse ':Ponder!foo@bar PART #mended_drum :Bye!'
    expect(@called).to be_true
  end

  it 'is correctly created when an user joins a channel' do
    @thaum.parse ':TheLibrarian!foo@bar JOIN #mended_drum'

    user = @thaum.user_list.find('TheLibrarian')
    channel = @thaum.channel_list.find('#mended_drum')

    @thaum.on :part do |event_data|
      expect(event_data[:part]).to be_kind_of Ponder::IRC::Events::Part
      expect(event_data[:part].user).to eql(user)
      expect(event_data[:part].channel).to eql(channel)
      expect(event_data[:part].message).to eql('Baba!')
      @called = true
    end

    @thaum.parse ':TheLibrarian!foo@bar PART #mended_drum :Baba!'
    expect(@called).to be_true
  end
end
