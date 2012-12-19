$LOAD_PATH.unshift(File.dirname(__FILE__))

require 'spec_helper'
require 'ponder'

describe Ponder::Thaum do
  before(:each) do
    @thaum = Ponder::Thaum.new
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

  it 'PING PONGs' do
    time = Time.now.to_i
    @thaum.should_receive(:send_data).with("PONG #{time}")
    @thaum.parse("PING #{time}")
  end

  it 'does not log PING PONGs' do
    time = Time.now.to_i
    @thaum.loggers.should_not_receive(:info).with(/ping/i)
    @thaum.loggers.should_not_receive(:info).with(/pong/i)
    @thaum.should_receive(:send_data).with("PONG #{time}")
    @thaum.parse("PING #{time}")
  end

  it 'logs PING PONGs when configured' do
    @thaum.config.hide_ping_pongs = false
    time = Time.now.to_i
    @thaum.loggers.should_receive(:info).with(/ping/i)
    @thaum.loggers.should_receive(:info).with(/pong/i)
    @thaum.should_receive(:send_data).with("PONG #{time}")
    @thaum.parse("PING #{time}")
  end
end
