$LOAD_PATH.unshift(File.dirname(__FILE__))

require 'spec_helper'
require 'ponder'

describe Ponder::Thaum do
  before(:each) do
    @thaum = Ponder::Thaum.new
  end

  it 'sets a default configuration' do
    @thaum.config.server.should eq('localhost')
    @thaum.config.port.should eq(6667)
    @thaum.config.nick.should eq('Ponder')
    @thaum.config.username.should eq('Ponder')
    @thaum.config.real_name.should eq('Ponder')
    @thaum.config.verbose.should be_true
    @thaum.config.logging.should be_false
    @thaum.config.reconnect.should be_true
    @thaum.config.reconnect_interval.should eq(30)

    @thaum.loggers.should be_an_instance_of(Ponder::Logging::LoggerList)
  end

  it 'sets the logger correctly' do
    Ponder::Logging::Twoflogger.should_receive(:new).twice
    @thaum = Ponder::Thaum.new { |t| t.logging = true }
  end

  it 'sets default callbacks' do
    @thaum.callbacks.should have(3)[:query]
  end

  context 'creates a correct default callback for' do
    it 'PING PONG' do
      time = Time.now.to_i
      @thaum.should_receive(:notice).with('Peter', "\001PING #{time}\001")
      EM.run do
        @thaum.process_callbacks(:query, {:type => :query, :nick => 'Peter', :message => "\001PING #{time}\001"})
        EM.schedule { EM.stop }
      end
    end

    it 'VERSION' do
      @thaum.should_receive(:notice).with('Peter', "\001VERSION Ponder #{Ponder::VERSION} (https://github.com/tbuehlmann/ponder)\001")
      EM.run do
        @thaum.process_callbacks(:query, {:type => :query, :nick => 'Peter', :message => "\001VERSION\001"})
        EM.schedule { EM.stop }
      end
    end

    it 'TIME' do
      @thaum.should_receive(:notice).with('Peter', "\001TIME #{Time.now.strftime('%a %b %d %H:%M:%S %Y')}\001")
      EM.run do
        @thaum.process_callbacks(:query, {:type => :query, :nick => 'Peter', :message => "\001TIME\001"})
        EM.schedule { EM.stop }
      end
    end
  end
end
