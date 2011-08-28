$LOAD_PATH.unshift(File.dirname(__FILE__))

require 'spec_helper'
require 'ponder'

describe Ponder::Thaum do
  before(:each) do
    @ponder = Ponder::Thaum.new
  end

  it 'sets a default configuration' do
    @ponder.config.server.should eql('localhost')
    @ponder.config.port.should equal(6667)
    @ponder.config.nick.should eql('Ponder')
    @ponder.config.username.should eql('Ponder')
    @ponder.config.real_name.should eql('Ponder')
    @ponder.config.verbose.should be_true
    @ponder.config.logging.should be_false
    @ponder.config.reconnect.should be_true
    @ponder.config.reconnect_interval.should equal(30)

    @ponder.logger.should be_an_instance_of(Ponder::Logger::BlindIo)
    @ponder.console_logger.should be_an_instance_of(Ponder::Logger::Twoflogger)
  end

  it 'sets the logger correctly' do
    Ponder::Logger::Twoflogger.should_receive(:new).twice
    @ponder = Ponder::Thaum.new { |t| t.logging = true }
  end

  it 'sets default callbacks' do
    @ponder.callbacks.should have(3)[:query]
  end

  context 'creates a correct default callback for' do
    it 'PING PONG' do
      time = Time.now.to_i
      @ponder.should_receive(:notice).with('Peter', "\001PING #{time}\001")
      EM.run do
        @ponder.process_callbacks(:query, {:nick => 'Peter', :message => "\001PING #{time}\001"})
        EM.schedule { EM.stop }
      end
    end

    it 'VERSION' do
      @ponder.should_receive(:notice).with('Peter', "\001VERSION Ponder #{Ponder::VERSION} (https://github.com/tbuehlmann/ponder)\001")
      EM.run do
        @ponder.process_callbacks(:query, {:nick => 'Peter', :message => "\001VERSION\001"})
        EM.schedule { EM.stop }
      end
    end

    it 'TIME' do
      @ponder.should_receive(:notice).with('Peter', "\001TIME #{Time.now.strftime('%a %b %d %H:%M:%S %Y')}\001")
      EM.run do
        @ponder.process_callbacks(:query, {:nick => 'Peter', :message => "\001TIME\001"})
        EM.schedule { EM.stop }
      end
    end
  end
end

