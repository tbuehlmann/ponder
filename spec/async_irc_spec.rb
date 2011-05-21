$LOAD_PATH.unshift(File.dirname(__FILE__))

require 'spec_helper'
require 'ponder/thaum'
require 'ponder/async_irc'

describe Ponder::AsyncIRC do
  before(:each) do
    @ponder = Ponder::Thaum.new
    @ponder.configure { |c| c.verbose = false }
  end

  describe Ponder::AsyncIRC::Whois do
    context 'tries to get whois information when' do
      it 'there is no such nick' do
        @ponder.should_receive(:raw).with('WHOIS not_online')
        EM.run do
          whois = @ponder.whois('not_online', 1.5)
          whois.callback do |result|
            result.should be_false
            EM.stop
          end
          whois.errback do
            fail 'Wrong Callback called'
            EM.stop
          end

          EM.next_tick { @ponder.parse(":server 401 Ponder not_online :No such nick\r\n") }
        end
      end

      it 'the user is online' do
        @ponder.should_receive(:raw).with('WHOIS Ridcully')
        EM.run do
          whois = @ponder.whois('Ridcully', 1.5)
          whois.callback do |result|
            result.should be_kind_of(Hash)
            result[:nick].should eql('Ridcully')
            result[:username].should eql('ridc')
            result[:host].should eql('host')
            result[:real_name].should eql('Ridcully the wizard')
      
            result[:server].should be_kind_of(Hash)
            result[:server][:address].should eql('foo.host.net')
            result[:server][:name].should eql('That host thing')
      
            result[:channels].should be_kind_of(Hash)
            result[:channels]['#foo'].should be_nil
            result[:channels]['##bar'].should be_nil
            result[:channels]['#baz'].should eql('<')
            result[:channels]['#sushi'].should eql('@')
            result[:channels]['#ramen'].should eql('+')
      
            result[:registered].should be_true
            EM.stop
          end
          whois.errback do
            fail 'Wrong Callback called'
            EM.stop
          end

          EM.next_tick do
            @ponder.parse(":server 311 Ponder Ridcully :ridc host * :Ridcully the wizard\r\n")
            @ponder.parse(":server 312 Ponder Ridcully foo.host.net :That host thing\r\n")
            @ponder.parse(":server 319 Ponder Ridcully :#foo ##bar <#baz @#sushi +#ramen\r\n")
            @ponder.parse(":server 330 Ponder Ridcully rid_ :is logged in as\r\n")
            @ponder.parse(":server 318 Ponder Ridcully :End of /WHOIS list.\r\n")
          end
        end
      end
    end

    context 'it tries to get channel information when' do
      it 'there is no such channel' do
        @ponder.should_receive(:raw).with('MODE #no_channel')

        EM.run do
          channel_info = @ponder.channel_info('#no_channel')
          channel_info.callback do |result|
            result.should be_false
            EM.stop
          end
          channel_info.errback do
            fail 'Wrong Callback called'
            EM.stop
          end

          EM.next_tick { @ponder.parse(":server 403 Ponder #no_channel :No such channel\r\n") }
        end
      end
    end
  end

  describe Ponder::AsyncIRC::Topic do    
    context 'tries to get a topic' do
      it ', adds the Deferrable object to the Set and deletes if afterwards for a success' do
        @ponder.should_receive(:raw).with('TOPIC #channel')
        EM.run do
          @ponder.deferrables.should be_empty
          topic = @ponder.get_topic('#channel')
          @ponder.deferrables.should include(topic)
          topic.callback do |result|
            @ponder.deferrables.should be_empty
            EM.stop
          end
          topic.errback do
            fail 'Wrong Callback called'
            EM.stop
          end

          EM.next_tick { @ponder.parse(":server 331 Ponder #channel :No topic is set.\r\n") }
        end
      end

      it ', adds the Deferrable object to the Set and deletes if afterwards for a failure (timeout)' do
        @ponder.should_receive(:raw).with('TOPIC #channel')
        EM.run do
          @ponder.deferrables.should be_empty
          topic = @ponder.get_topic('#channel', 1.5)
          @ponder.deferrables.should include(topic)
          topic.callback do |result|
            fail 'Wrong Callback called'
            EM.stop
          end
          topic.errback do
            @ponder.deferrables.should be_empty
            EM.stop
          end
        end
      end

      it 'when there is no topic set' do
        @ponder.should_receive(:raw).with('TOPIC #channel')
        EM.run do
          @ponder.deferrables.should be_empty
          topic = @ponder.get_topic('#channel', 2)
          @ponder.deferrables.should include(topic)
          topic.callback do |result|
            result.should eql({:raw_numeric => 331, :message => 'No topic is set'})
            @ponder.deferrables.should be_empty
            EM.stop
          end
          topic.errback do
            fail 'Wrong Callback called'
            EM.stop
          end

          EM.next_tick { @ponder.parse(":server 331 Ponder #channel :No topic is set.\r\n") }
        end
      end

      it 'when there is no such channel' do
        @ponder.should_receive(:raw).with('TOPIC #no_channel')
        EM.run do
          topic = @ponder.get_topic('#no_channel')
          topic.callback do |result|
            result.should eql({:raw_numeric => 403, :message => 'No such channel'})
            EM.stop
          end
          topic.errback do
            fail 'Wrong Callback called'
            EM.stop
          end

          EM.next_tick { @ponder.parse(":server 403 Ponder #no_channel :No such channel\r\n") }
        end
      end

      it "you're not on that channel" do
        @ponder.should_receive(:raw).with('TOPIC #channel')
        EM.run do
          topic = @ponder.get_topic('#channel')
          topic.callback do |result|
            result.should eql({:raw_numeric => 442, :message => "You're not on that channel"})
            EM.stop
          end
          topic.errback do
            fail 'Wrong Callback called'
            EM.stop
          end

          EM.next_tick { @ponder.parse(":server 442 Ponder #channel :You're not on that channel\r\n") }
        end
      end
    end
  end
end
