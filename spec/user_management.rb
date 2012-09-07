$LOAD_PATH.unshift(File.dirname(__FILE__))

require 'spec_helper'
require 'ponder/thaum'

describe 'User Management' do
  before(:each) do
    @thaum = Ponder::Thaum.new do |t|
      t.nick    = 'Ponder'
      t.verbose = false
    end
  end

  context 'Connecting to the server' do
    describe 'The Thaum' do
      it 'adds itself to the user_list when connected to the server' do
        @thaum.user_list.users.should be_empty
        @thaum.parse(':server 376 Ponder :End of /MOTD command.')
        @thaum.user_list.users.should have(1).user
      end
    end
  end

  context 'Connected to the server' do
    describe 'The Thaum' do
      before(:each) do
        @thaum.parse(':server 376 Ponder :End of /MOTD command.')
      end

      it 'adds an user to the user_list when the user joins a channel the Thaum is in' do
        @thaum.parse(':Ponder!foo@bar JOIN #mended_drum')
        @thaum.user_list.users.should have(1).user
        @thaum.parse(':TheLibrarian!foo@bar JOIN #mended_drum')
        @thaum.user_list.users.should have(2).users
      end

      it 'adds an user to the channel when the user joins a channel the Thaum is in' do
        @thaum.parse(':Ponder!foo@bar JOIN #mended_drum')
        channel = @thaum.channel_list.find('#mended_drum')
        channel.users.should have(1).user
        @thaum.parse(':TheLibrarian!foo@bar JOIN #mended_drum')
        channel.users.should have(2).users
      end

      it 'adds user to the user_list when the Thaum joins a channel with users in it' do
        @thaum.parse(':Ponder!foo@bar JOIN #mended_drum')
        channel = @thaum.channel_list.find('#mended_drum')
        @thaum.user_list.users.should have(1).user
        @thaum.parse(':server 353 Ponder @ #mended_drum :Ponder @TheLibrarian +Ridcully')
        @thaum.user_list.users.should have(3).users
      end

      it 'adds user to the user_list when the Thaum joins a channel with users in it without doublets' do
        @thaum.parse(':Ponder!foo@bar JOIN #mended_drum')
        @thaum.parse(':server 353 Ponder @ #mended_drum :Ponder @TheLibrarian +Ridcully')
        @thaum.parse(':Ponder!foo@bar JOIN #library')
        @thaum.parse(':server 353 Ponder @ #library :Ponder TheLibrarian')
        @thaum.user_list.users.should have(3).users
      end

      it 'adds user to a channel when the Thaum joins a channel with users in it' do
        @thaum.parse(':Ponder!foo@bar JOIN #mended_drum')
        channel = @thaum.channel_list.find('#mended_drum')
        channel.users.should have(1).user
        @thaum.parse(':server 353 Ponder @ #mended_drum :Ponder @TheLibrarian +Ridcully')
        channel.users.should have(3).users
      end

      it 'removes an user from the user_list when quitting' do
        @thaum.user_list.users.should have(1).user
        @thaum.parse(':Ponder!foo@bar JOIN #mended_drum')
        @thaum.parse(':server 353 Ponder @ #mended_drum :Ponder @TheLibrarian +Ridcully')
        @thaum.user_list.users.should have(3).users
        @thaum.parse(':TheLibrarian!foo@bar QUIT :Going to eat a banana.')
        @thaum.user_list.users.should have(2).users
      end

      it 'removes an user from all channels when quitting' do
        @thaum.parse(':Ponder!foo@bar JOIN #mended_drum')
        @thaum.parse(':server 353 Ponder @ #mended_drum :Ponder @TheLibrarian')
        @thaum.parse(':Ponder!foo@bar JOIN #library')
        @thaum.parse(':server 353 Ponder @ #library :Ponder +TheLibrarian')
        mended_drum = @thaum.channel_list.find('#mended_drum')
        mended_drum.users.should have(2).users
        library = @thaum.channel_list.find('#library')
        library.users.should have(2).users
        @thaum.parse(':TheLibrarian!foo@bar QUIT :Going to eat a banana.')
        mended_drum.users.should have(1).users
        library.users.should have(1).users
      end

      it 'removes an user from a channel when the user parts' do
        @thaum.parse(':Ponder!foo@bar JOIN #mended_drum')
        @thaum.parse(':server 353 Ponder @ #mended_drum :Ponder @TheLibrarian')
        channel = @thaum.channel_list.find('#mended_drum')
        channel.users.should have(2).users
        @thaum.parse(':TheLibrarian!foo@bar PART #mended_drum')
        channel.users.should have(1).user
      end

      it 'removes an user from a channel when being kicked' do
        @thaum.parse(':Ponder!foo@bar JOIN #mended_drum')
        @thaum.parse(':server 353 Ponder @ #mended_drum :Ponder @TheLibrarian')
        channel = @thaum.channel_list.find('#mended_drum')
        channel.users.should have(2).users
        @thaum.parse(':Ponder!foo@bar KICK #mended_drum TheLibrarian :Go out!')
        channel.users.should have(1).user
      end

      it 'does not remove an user from the user_list when the user parts a channel and the user in another channel the Thaum is in' do
        @thaum.parse(':Ponder!foo@bar JOIN #mended_drum')
        @thaum.parse(':server 353 Ponder @ #mended_drum :Ponder @TheLibrarian')
        @thaum.parse(':Ponder!foo@bar JOIN #library')
        @thaum.parse(':server 353 Ponder @ #library :Ponder @TheLibrarian')
        @thaum.user_list.users.should have(2).users
        @thaum.parse(':TheLibrarian!foo@bar PART #mended_drum')
        @thaum.user_list.users.should have(2).users
      end

      it 'removes an user from the user_list when the user parting the last channel the Thaum is in' do
        @thaum.parse(':Ponder!foo@bar JOIN #mended_drum')
        @thaum.parse(':server 353 Ponder @ #mended_drum :Ponder @TheLibrarian')
        @thaum.user_list.users.should have(2).users
        @thaum.parse(':TheLibrarian!foo@bar PART #mended_drum')
        @thaum.user_list.users.should have(1).user
      end

      it 'removes an user from the user_list when being kicked from the last channel the Thaum is in' do
        @thaum.parse(':Ponder!foo@bar JOIN #mended_drum')
        @thaum.parse(':server 353 Ponder @ #mended_drum :Ponder @TheLibrarian')
        @thaum.user_list.users.should have(2).users
        @thaum.parse(':Ponder!foo@bar KICK #mended_drum TheLibrarian :Go out!')
        @thaum.user_list.users.should have(1).user
      end

      it 'removes an user from the user_list when parting if the user is no other channel the Thaum is in' do
        @thaum.parse(':Ponder!foo@bar JOIN #mended_drum')
        @thaum.parse(':server 353 Ponder @ #mended_drum :Ponder @TheLibrarian')
        @thaum.user_list.users.should have(2).users
        @thaum.parse(':Ponder!foo@bar PART #mended_drum')
        @thaum.user_list.users.should have(1).users
      end
    end
  end
end
