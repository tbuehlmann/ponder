$LOAD_PATH.unshift(File.dirname(__FILE__))

require 'spec_helper'
require 'ponder/thaum'

describe Ponder::Callback do
  before(:all) { @proc = Proc.new { } }

  before(:each) do
    @ponder = Ponder::Thaum.new
    @ponder.configure { |c| c.verbose = true }
  end

  context 'tries to create a callback' do
    it 'with valid arguments' do
      lambda { Ponder::Callback.new(:channel, /foo/, @proc) }.should_not raise_error
    end

    it 'with an invalid type' do
      lambda { Ponder::Callback.new(:invalid, /foo/, @proc) }.should raise_error(TypeError)
    end

    it 'with an invalid match' do
      lambda { Ponder::Callback.new(:channel, 8, @proc) }.should raise_error(TypeError)
    end

    it 'with an invalid proc' do
      lambda { Ponder::Callback.new(:channel, /foo/, {}, 8) }.should raise_error(TypeError)
    end
  end

  it "calls the callback's proc on right match" do
    callback = Ponder::Callback.new(:channel, /wizzard/, {}, Proc.new { 8 })
    callback.call(:channel, {:message => 'I like wizzards'}).should eql(8)
  end

  it "does not call the callback's proc on the wrong match" do
    p = Proc.new { 8 }
    p.should_not_receive(:call)
    callback = Ponder::Callback.new(:channel, /wizzard/, p)
    callback.call(:channel, {:message => 'I like hot dogs'}).should be_nil
  end

  it "calls the callback's proc on the right match and the right event type" do
    # `@proc.should_receive(:call).once` does not work here in 1.8.7
    proc = Proc.new { @called = true }
    @ponder.on(:channel, /wizzard/, &proc)
    EM.run do
      @ponder.process_callbacks(:channel, {:message => 'I like wizzards'})
      EM.schedule { EM.stop }
    end

    @called.should be_true
  end

  it "calls the callback's proc on the right match and the right event type with multiple types" do
    # `@proc.should_receive(:call).once` does not work here in 1.8.7
    proc = Proc.new { @called = true }
    @ponder.on([:channel, :query], /wizzard/, &proc)
    EM.run do
      @ponder.process_callbacks(:query, {:message => 'I like wizzards'})
      EM.schedule { EM.stop }
    end

    @called.should be_true
  end
end

