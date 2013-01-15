$LOAD_PATH.unshift(File.dirname(__FILE__))

require 'spec_helper'
require 'ponder/thaum'

describe Ponder::IRC::Events::Kick do
  before(:each) do
    @thaum = Ponder::Thaum.new do |config|
      config.nick = 'Ponder'
      config.verbose = false
    end

    # Connected to a server.
    @thaum.parse ':server 376 Ponder :End of /MOTD command.'
    @thaum.parse ':Ponder!foo@bar JOIN #mended_drum'
    @thaum.parse ':TheLibrarian!foo@bar JOIN #mended_drum'
  end

  it 'is correctly created when the Thaum is being kicked off a channel' do
    thaum_user = @thaum.user_list.find(@thaum.config.nick)
    channel = @thaum.channel_list.find('#mended_drum')

    @thaum.on :kick do |event_data|
      expect(event_data[:kick]).to be_kind_of Ponder::IRC::Events::Kick
      expect(event_data[:kick].kicker).to be_kind_of Ponder::User
      expect(event_data[:kick].victim).to be_kind_of Ponder::User
      expect(event_data[:kick].victim).to eql(thaum_user)
      expect(event_data[:kick].message).to eql('Get out!')
      expect(event_data[:kick].channel).to eql(channel)

      @called = true
    end

    @thaum.parse ':TheLibrarian!foo@bar KICK #mended_drum Ponder :Get out!'
    expect(@called).to be_true
  end

  it 'is correctly created when an user is being kicked off a channel' do
    thaum_user = @thaum.user_list.find('Ponder')
    user = @thaum.user_list.find('TheLibrarian')
    channel = @thaum.channel_list.find('#mended_drum')

    @thaum.on :kick do |event_data|
      expect(event_data[:kick]).to be_kind_of Ponder::IRC::Events::Kick
      expect(event_data[:kick].kicker).to be_kind_of Ponder::User
      expect(event_data[:kick].victim).to be_kind_of Ponder::User
      expect(event_data[:kick].kicker).to eql(thaum_user)
      expect(event_data[:kick].victim).to eql(user)
      expect(event_data[:kick].message).to eql('Get out!')
      expect(event_data[:kick].channel).to eql(channel)

      @called = true
    end

    @thaum.parse ':pONDER!foo@bar KICK #mended_drum TheLibrarian :Get out!'
    expect(@called).to be_true
  end
end
