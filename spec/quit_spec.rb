$LOAD_PATH.unshift(File.dirname(__FILE__))

require 'spec_helper'
require 'ponder/thaum'

describe Ponder::IRC::Events::Quit do
  before(:each) do
    @thaum = Ponder::Thaum.new do |config|
      config.nick = 'Ponder'
      config.verbose = false
    end

    # Connected to a server.
    @thaum.parse ':server 376 Ponder :End of /MOTD command.'
  end

  it 'is correctly created when the Thaum quits from the server' do
  	@thaum.parse ':Ponder!foo@bar JOIN #mended_drum'
  	@thaum.parse ':Ponder!foo@bar JOIN #unseen_university'

  	thaum_user = @thaum.user_list.find(@thaum.config.nick)

    @thaum.on :quit do |event_data|
      @called = true

      expect(event_data[:quit]).to be_kind_of Ponder::IRC::Events::Quit
      expect(event_data[:quit].user).to eql(thaum_user)
      expect(event_data[:quit].channels.keys).to eql(['#mended_drum', '#unseen_university'])
      expect(event_data[:quit].message).to eql('Bye!')
    end

    @thaum.parse ':Ponder!foo@bar QUIT :Bye!'
    expect(@called).to be_true
  end

  it 'is correctly created when an user quits from the server' do
  	@thaum.parse ':Ponder!foo@bar JOIN #mended_drum'
  	@thaum.parse ':Ponder!foo@bar JOIN #unseen_university'
  	@thaum.parse ':Ponder!foo@bar JOIN #lancre'

  	@thaum.parse ':TheLibrarian!foo@bar JOIN #mended_drum'
  	@thaum.parse ':TheLibrarian!foo@bar JOIN #unseen_university'

  	user = @thaum.user_list.find('TheLibrarian')

    @thaum.on :quit do |event_data|
      @called = true

      expect(event_data[:quit]).to be_kind_of Ponder::IRC::Events::Quit
      expect(event_data[:quit].user).to eql(user)
      expect(event_data[:quit].channels.keys).to eql(['#mended_drum', '#unseen_university'])
      expect(event_data[:quit].message).to eql('Bye!')
    end

    @thaum.parse ':TheLibrarian!foo@bar QUIT :Bye!'
    expect(@called).to be_true
  end
end
