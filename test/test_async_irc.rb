$LOAD_PATH.unshift(File.dirname(__FILE__))

require 'test_helper'
require 'ponder/async_irc'

include Ponder::AsyncIRC
def raw(*args)
end

class TestAsyncIRC < Test::Unit::TestCase
  def setup
    @observer_queues = {}
  end
  
  def test_get_topic_no_topic_set
    topic = Thread.new do
      assert_equal({:raw_numeric => 331, :message => 'No topic is set'}, get_topic('#mended_drum'))
    end
    
    event_loop = Thread.new do
      loop do
        message = ':server 331 Ponder #mended_drum :No topic is set.'
        @observer_queues.each do |queue, regexps|
          regexps.each do |regexp|
            if message =~ regexp
              queue << message
            end
          end
        end
        
        sleep 0.1
      end
    end
    topic.join
  end
  
  def test_get_topic
    topic = Thread.new do
      assert_equal({:raw_numeric => 332, :message => 'No dwarfs in here!'}, get_topic('#mended_drum'))
    end
    
    event_loop = Thread.new do
      loop do
        message = ':server 332 Ponder #mended_drum :No dwarfs in here!'
        @observer_queues.each do |queue, regexps|
          regexps.each do |regexp|
            if message =~ regexp
              queue << message
            end
          end
        end
        
        sleep 0.1
      end
    end
    topic.join
  end
  
  def test_get_topic_no_such_channel
    topic = Thread.new do
      assert_equal({:raw_numeric => 403, :message => 'No such channel'}, get_topic('#mended_drum'))
    end
    
    event_loop = Thread.new do
      loop do
        message = ':server 403 Ponder #mended_drum :No such channel'
        @observer_queues.each do |queue, regexps|
          regexps.each do |regexp|
            if message =~ regexp
              queue << message
            end
          end
        end
        
        sleep 0.1
      end
    end
    topic.join
  end
  
  def test_get_topic_you_are_not_on_that_channel
    topic = Thread.new do
      assert_equal({:raw_numeric => 442, :message => "You're not on that channel"}, get_topic('#mended_drum'))
    end
    
    event_loop = Thread.new do
      loop do
        message = ":server 442 Ponder #mended_drum :You're not on that channel"
        @observer_queues.each do |queue, regexps|
          regexps.each do |regexp|
            if message =~ regexp
              queue << message
            end
          end
        end
        
        sleep 0.1
      end
    end
    topic.join
  end
end

