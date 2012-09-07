$LOAD_PATH.unshift(File.dirname(__FILE__))

require 'spec_helper'
require 'ponder/thaum'

describe 'Channel Management' do
  before(:each) do
    @thaum = Ponder::Thaum.new do |t|
      t.nick    = 'Ponder'
      t.verbose = false
    end

    # The Thaum is connected (and thus in the user_list).
    @thaum.parse(':server 376 Ponder :End of /MOTD command.')
  end

  context 'The Thaum' do
    it 'adds a channel to the channel_list when joining a channel' do
      @thaum.channel_list.channels.values.should be_empty
      @thaum.parse(':Ponder!foo@bar JOIN #mended_drum')
      @thaum.channel_list.channels.should have(1).channel
      @thaum.channel_list.channels.values.first.name.should eq('#mended_drum')
    end

    it 'removes a channel from the channel_list when leaving a channel' do
      @thaum.parse(':Ponder!foo@bar JOIN #mended_drum')
      @thaum.channel_list.channels.should have(1).channel
      @thaum.parse(':Ponder!foo@bar PART #mended_drum')
      @thaum.channel_list.channels.values.should be_empty
    end

    it 'removes a channel from the channel_list when being kicked from a channel' do
      @thaum.parse(':Ponder!foo@bar JOIN #mended_drum')
      @thaum.channel_list.channels.should have(1).channel
      @thaum.parse(':TheLibrarian!foo@bar KICK #mended_drum Ponder :No humans allowed!')
      @thaum.channel_list.channels.values.should be_empty
    end

    it 'removes all channels from the channel_list when quitting' do
      @thaum.parse(':Ponder!foo@bar JOIN #mended_drum')
      @thaum.parse(':Ponder!foo@bar JOIN #library')
      @thaum.channel_list.channels.should have(2).channels
      @thaum.parse(':Ponder!foo@bar QUIT :Bye mates!')
      @thaum.channel_list.channels.values.should be_empty
    end
  end
end
