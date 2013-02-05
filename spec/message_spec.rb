require 'spec_helper'

describe Ponder::IRC::Events::Message do
  before(:each) do
    @thaum = Ponder::Thaum.new do |config|
      config.nick = 'Ponder'
      config.verbose = false
    end

    # Connected to a server.
    @thaum.parse ':server 376 Ponder :End of /MOTD command.'
  end

  it 'is correctly created when an user writes to a channel' do
    Ponder::Channel.any_instance.stub(:get_mode)
    @thaum.parse ':Ponder!foo@bar JOIN #mended_drum'
    @thaum.parse ':TheLibrarian!foo@bar JOIN #mended_drum'
    channel = @thaum.channel_list.find('#mended_drum')
    user = @thaum.user_list.find('TheLibrarian')

    @thaum.on :channel do |event_data|
      expect(event_data[:message]).to be_kind_of Ponder::IRC::Events::Message
      expect(event_data[:message].user).to eql(user)
      expect(event_data[:message].body).to eql('Bananas?')
      expect(event_data[:message].channel).to eql(channel)

      @called = true
    end

    @thaum.parse ':TheLibrarian!foo@bar PRIVMSG #mended_drum :Bananas?'
    expect(@called).to be_true
  end

  it 'is correctly created when an user writes privately to the Thaum' do
    Ponder::Channel.any_instance.stub(:get_mode)
    @thaum.parse ':Ponder!foo@bar JOIN #mended_drum'
    @thaum.parse ':TheLibrarian!foo@bar JOIN #mended_drum'
    user = @thaum.user_list.find('TheLibrarian')

    @thaum.on :query do |event_data|
      expect(event_data[:message]).to be_kind_of Ponder::IRC::Events::Message
      expect(event_data[:message].user).to eql(user)
      expect(event_data[:message].body).to eql('Bananas?')
      expect { event_data[:message].channel }.to raise_error(NoMethodError)

      @called = true
    end

    @thaum.parse ':TheLibrarian!foo@bar PRIVMSG Ponder :Bananas?'
    expect(@called).to be_true
  end
end
