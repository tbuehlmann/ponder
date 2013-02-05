require 'spec_helper'

describe Ponder::User do
  before(:each) do
    @thaum = Ponder::Thaum.new do |t|
      t.nick    = 'Ponder'
      t.verbose = false
    end

    # Connected to a server.
    @thaum.parse ':server 376 Ponder :End of /MOTD command.'
  end

  context 'checks the online status' do
    describe 'of an user' do
      it "which is online and in one of the Thaum's channels" do
        Ponder::Channel.any_instance.stub(:get_mode)
        # Thaum joining a channel.
        @thaum.parse(':Ponder!foo@bar JOIN #mended_drum')

        # User joining the same channel.
        @thaum.parse(':TheLibrarian!foo@bar JOIN #mended_drum')

        user = Ponder::User.new('TheLibrarian', @thaum)
        user.should_not_receive(:whois)
        user.online?.should be_true
      end

      it "which is online and NOT in one of the Thaum's channels" do
        Ponder::Channel.any_instance.stub(:get_mode)
        user = Ponder::User.new('TheLibrarian', @thaum)
        user.should_receive(:online?).once.and_call_original
        user.should_receive(:raw).with('WHOIS TheLibrarian').once

        Fiber.new { @online_status = user.online? }.resume

        @thaum.parse(':server 311 Ponder TheLibrarian foo bar * :The Librarian')
        @thaum.parse(':server 318 Ponder TheLibrarian :End of /WHOIS list.')
        
        @online_status.should be_true
      end

      it 'which is not online' do
        Ponder::Channel.any_instance.stub(:get_mode)
        user = Ponder::User.new('TheLibrarian', @thaum)
        user.should_receive(:online?).once.and_call_original
        user.should_receive(:raw).with('WHOIS TheLibrarian').once

        Fiber.new { @online_status = user.online? }.resume

        @thaum.parse(':server 401 Ponder TheLibrarian :No such nick/channel')
        @thaum.parse(':server 318 Ponder TheLibrarian :End of /WHOIS list.')
        
        @online_status.should be_false
      end
    end
  end
end
