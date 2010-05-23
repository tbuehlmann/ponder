require 'pathname'
require 'thread'
autoload :FileUtils, 'fileutils'

module Ponder
  module Logger
    class Twoflogger
      attr_accessor :level, :levels, :time_format
      
      def initialize(destination = Ponder.root.join('logs', 'log.log'), level = :debug, time_format = '%Y-%m-%d %H:%M:%S', levels = {:debug => 0, :info => 1, :warn => 2, :error => 3, :fatal => 4, :unknown => 5})
        @level = level
        @time_format = time_format
        @levels = levels
        @queue = Queue.new
        @mutex = Mutex.new
        @running = false
        
        define_level_shorthand_methods
        self.log_dev = destination
      end
      
      def start_logging
        @running = true
        @thread = Thread.new do
          begin
            while @running do
              write(@queue.pop)
            end
          ensure
            @log_dev.close if @log_dev.is_a?(File)
          end
        end
      end
      
      def stop_logging
        @running = false
      end
      
      def log_dev=(destination)
        stop_logging
        
        if destination.is_a?(Pathname)
          unless destination.exist?
            unless destination.dirname.directory?
              FileUtils.mkdir_p destination.dirname
            end
            
            File.new(destination, 'w+')
          end
          @log_dev = File.open(destination, 'a+')
          @log_dev.sync = true
        elsif destination.is_a?(IO)
          @log_dev = destination
        else
          raise TypeError, 'need a Pathname or IO'
        end
      end
      
      private
      
      def define_level_shorthand_methods
        @levels.each_pair do |level_name, severity|
          self.class.send(:define_method, level_name, Proc.new { |*messages| queue(severity, *messages) })
        end
      end
      
      def queue(severity, *messages)
        raise(ArgumentError, 'Need a message') if messages.empty?
        raise(ArgumentError, 'Need messages that respond to #to_s') if messages.any? { |message| !message.respond_to?(:to_s) }
        
        if severity >= @levels[@level]
          message_hashes = messages.map { |message| {:severity => severity, :message => message} }
          
          @mutex.synchronize do
            message_hashes.each do |hash|
              @queue << hash
            end
          end
        end
      end
      
      def write(*message_hashes)
        begin
          message_hashes.each do |hash|
            @log_dev.puts "#{@levels.index(hash[:severity])} #{Time.now.strftime(@time_format)} #{hash[:message]}"
          end
        rescue => e
          puts e.message, *e.backtrace
        end
      end
    end
  end
end
