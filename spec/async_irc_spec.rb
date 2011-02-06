$LOAD_PATH.unshift(File.dirname(__FILE__))

require 'spec_helper'
require 'ponder/thaum'

describe Ponder::AsyncIRC do
  PERIODIC_TIME = 0.01

  before(:each) do
    @ponder = Ponder::Thaum.new
    @ponder.configure { |c| c.verbose = false }
  end

  context 'tries to get a topic when' do
    it 'there is no topic set' do
      @ponder.should_receive(:raw).with('TOPIC #channel')
      EM.run do
        EM.defer(Proc.new { @result = @ponder.get_topic('#channel') }, Proc.new { EM.schedule { EM.stop } })
        EM::PeriodicTimer.new(PERIODIC_TIME) { @ponder.parse(":server 331 Ponder #channel :No topic is set.\r\n") }
      end
      @result.should eql({:raw_numeric => 331, :message => 'No topic is set'})
    end

    it 'there is no topic set' do
      @ponder.should_receive(:raw).with('TOPIC #channel')
      EM.run do
        EM.defer(Proc.new { @result = @ponder.get_topic('#channel') }, Proc.new { EM.schedule { EM.stop } })
        EM::PeriodicTimer.new(PERIODIC_TIME) { @ponder.parse(":server 332 Ponder #channel :topic content\r\n") }
      end
      @result.should eql({:raw_numeric => 332, :message => 'topic content'})
    end

    it 'there is no such channel' do
      @ponder.should_receive(:raw).with('TOPIC #no_channel')
      EM.run do
        EM.defer(Proc.new { @result = @ponder.get_topic('#no_channel') }, Proc.new { EM.schedule { EM.stop } })
        EM::PeriodicTimer.new(PERIODIC_TIME) { @ponder.parse(":server 403 Ponder #no_channel :No such channel\r\n") }
      end
      @result.should eql({:raw_numeric => 403, :message => 'No such channel'})
    end

    it "you're not on that channel" do
      @ponder.should_receive(:raw).with('TOPIC #channel')
      EM.run do
        EM.defer(Proc.new { @result = @ponder.get_topic('#channel') }, Proc.new { EM.schedule { EM.stop } })
        EM::PeriodicTimer.new(PERIODIC_TIME) { @ponder.parse(":server 442 Ponder #channel :You're not on that channel\r\n") }
      end
      @result.should eql({:raw_numeric => 442, :message => "You're not on that channel"})
    end
  end

  context 'it tries to get channel information when' do
    it 'there is no such channel' do
      @ponder.should_receive(:raw).with('MODE #no_channel')
      EM.run do
        EM.defer(Proc.new { @result = @ponder.channel_info('#no_channel') }, Proc.new { EM.schedule { EM.stop } })
        EM::PeriodicTimer.new(PERIODIC_TIME) { @ponder.parse(":server 403 Ponder #no_channel :No such channel\r\n") }
      end
      @result.should be_false
    end

    it "you're not on that channel" do
      @ponder.should_receive(:raw).with('MODE #channel')
      EM.run do
        EM.defer(Proc.new { @result = @ponder.channel_info('#channel') }, Proc.new { EM.schedule { EM.stop } })
        EM::PeriodicTimer.new(PERIODIC_TIME) { @ponder.parse(":server 442 Ponder #channel :You're not on that channel\r\n") }
      end
      @result.should be_false
    end

    it "there are regular channel modes" do
      @ponder.should_receive(:raw).with('MODE #channel')
      EM.run do
        EM.defer(Proc.new { @result = @ponder.channel_info('#channel') }, Proc.new { EM.schedule { EM.stop } })
        EM::PeriodicTimer.new(PERIODIC_TIME) do
          @ponder.parse(":server 324 Ponder #channel +cnst\r\n")
          @ponder.parse(":server 329 Ponder #channel 1233034048\r\n")
        end
      end
      @result.should be_kind_of(Hash)
      @result[:modes].should include('c', 'n', 's', 't')
      @result[:created_at].should eql(Time.at(1233034048))
    end

    it "there are regular channel modes with a limit" do
      @ponder.should_receive(:raw).with('MODE #channel')
      EM.run do
        EM.defer(Proc.new { @result = @ponder.channel_info('#channel') }, Proc.new { EM.schedule { EM.stop } })
        EM::PeriodicTimer.new(PERIODIC_TIME) do
          @ponder.parse(":server 324 Ponder #channel +cnstl 8\r\n")
          @ponder.parse(":server 329 Ponder #channel 1233034048\r\n")
        end
      end
      @result.should be_kind_of(Hash)
      @result[:modes].should include('c', 'n', 's', 't')
      @result[:created_at].should eql(Time.at(1233034048))
      @result[:channel_limit].should equal(8)
    end
  end

  context 'tries to get whois information when' do
    it 'there is no such nick' do
      @ponder.should_receive(:raw).with('WHOIS not_online')
      EM.run do
        EM.defer(Proc.new { @result = @ponder.whois('not_online') }, Proc.new { EM.schedule { EM.stop } })
        EM::PeriodicTimer.new(PERIODIC_TIME) { @ponder.parse(":server 401 Ponder not_online :No such nick\r\n") }
      end
      @result.should be_false
    end

    it 'the user is online' do
      @ponder.should_receive(:raw).with('WHOIS Ridcully')
      EM.run do
        EM.defer(Proc.new { @result = @ponder.whois('Ridcully') }, Proc.new { EM.schedule { EM.stop } })
        EM::PeriodicTimer.new(PERIODIC_TIME) do
          @ponder.parse(":server 311 Ponder Ridcully :ridc host * :Ridcully the wizard\r\n")
          @ponder.parse(":server 312 Ponder Ridcully foo.host.net :That host thing\r\n")
          @ponder.parse(":server 319 Ponder Ridcully :#foo ##bar <#baz @#sushi +#ramen\r\n")
          @ponder.parse(":server 330 Ponder Ridcully rid_ :is logged in as\r\n")
          @ponder.parse(":server 318 Ponder Ridcully :End of /WHOIS list.\r\n")
        end
      end

      @result.should be_kind_of(Hash)
      @result[:nick].should eql('Ridcully')
      @result[:username].should eql('ridc')
      @result[:host].should eql('host')
      @result[:real_name].should eql('Ridcully the wizard')

      @result[:server].should be_kind_of(Hash)
      @result[:server][:address].should eql('foo.host.net')
      @result[:server][:name].should eql('That host thing')

      @result[:channels].should be_kind_of(Hash)
      @result[:channels]['#foo'].should be_nil
      @result[:channels]['##bar'].should be_nil
      @result[:channels]['#baz'].should eql('<')
      @result[:channels]['#sushi'].should eql('@')
      @result[:channels]['#ramen'].should eql('+')

      @result[:registered].should be_true
    end
  end
end

