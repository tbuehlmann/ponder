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
      @ponder.should_receive(:raw).with('TOPIC #no_channel')
      EM.run do
        EM.defer(Proc.new { @result = @ponder.get_topic('#no_channel') }, Proc.new { EM.schedule { EM.stop } })
        EM::PeriodicTimer.new(PERIODIC_TIME) { @ponder.parse(":server 442 Ponder #no_channel :You're not on that channel\r\n") }
      end
      @result.should eql({:raw_numeric => 442, :message => "You're not on that channel"})
    end
  end
end

