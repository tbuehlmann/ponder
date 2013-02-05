require 'spec_helper'

describe Ponder::IRC::Events::Join do
  before(:each) do
    @thaum = Ponder::Thaum.new do |config|
      config.nick = 'Ponder'
      config.verbose = false
    end

    # Connected to a server.
    @thaum.parse ':server 376 Ponder :End of /MOTD command.'
  end

  it 'is correctly created when the Thaum joins a channel' do
    Ponder::Channel.any_instance.stub(:get_mode)
    thaum_user = @thaum.user_list.find(@thaum.config.nick)

    @thaum.on :join do |event_data|
      channel = @thaum.channel_list.find('#mended_drum')
      expect(event_data[:join]).to be_kind_of Ponder::IRC::Events::Join
      expect(event_data[:join].user).to eql(thaum_user)
      expect(event_data[:join].channel).to eql(channel)
      @called = true
    end

    @thaum.parse ':Ponder!foo@bar JOIN #mended_drum'
    expect(@called).to be_true
  end

  it 'is correctly created when an user joins a channel' do
    Ponder::Channel.any_instance.stub(:get_mode)
    @thaum.parse ':Ponder!foo@bar JOIN #mended_drum'
    
    channel = @thaum.channel_list.find('#mended_drum')

    @thaum.on :join do |event_data|
      user = @thaum.user_list.find('TheLibrarian')
      expect(event_data[:join]).to be_kind_of Ponder::IRC::Events::Join
      expect(event_data[:join].user).to eql(user)
      expect(event_data[:join].channel).to eql(channel)
      @called = true
    end

    @thaum.parse ':TheLibrarian!foo@bar JOIN #mended_drum'
    expect(@called).to be_true
  end
end
