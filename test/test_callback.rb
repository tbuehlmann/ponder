require 'pathname'
$LOAD_PATH.unshift Pathname(__FILE__).dirname.expand_path
require 'test_helper'

require 'ponder/callback'

module Ponder
  class Callback
    attr_accessor :type, :match, :proc
  end
end

class TestCallback < Test::Unit::TestCase
  def setup
    @empty_proc = Proc.new { }
  end
  
  def test_perfect_case
    callback = Ponder::Callback.new(:channel, /foo/, @empty_proc)
    
    assert_equal(:channel, callback.type)
    assert_equal(/foo/, callback.match)
    assert_equal(@empty_proc, callback.proc)
  end
  
  def test_wrong_type
    assert_raise(TypeError) do
      Ponder::Callback.new(8, /foo/, @empty_proc)
    end
  end
  
  def test_unsupported_type
    assert_raise(TypeError) do
      Ponder::Callback.new(:DEATH, /foo/, @empty_proc)
    end
  end
  
  def test_wrong_regexp
    assert_raise(TypeError) do
      Ponder::Callback.new(:channel, 8, @empty_proc)
    end
  end
  
  def test_proc
    proc = Proc.new { 7 + 1 }
    
    assert_equal(proc, Ponder::Callback.new(:channel, //, proc).proc)
  end
  
  def test_call
    proc = Proc.new { 8 }
    
    assert_equal(8, Ponder::Callback.new(:channel, /wizzard/, proc).call(:channel, {:message => 'I like wizzards'}))
    assert_nil(Ponder::Callback.new(:channel, /wizzard/, proc).call(:channel, {:message => 'I am a wizard'}))
  end
end
