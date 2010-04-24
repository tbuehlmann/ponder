require 'thread'
autoload :FileUtils, 'fileutils'

module Ponder
  class TwoFlogger
    DEBUG   = 0
    INFO    = 1
    WARN    = 2
    ERROR   = 3
    FATAL   = 4
    UNKNOWN = 5
    LEVEL   = ['DEBUG', 'INFO', 'WARN', 'ERROR', 'FATAL', 'UNKNOWN']
    
    attr_accessor :level, :time_format
    
    def initialize(dirpath = Pathname($0).dirname.join('logs').expand_path, filename = 'log.log', level = DEBUG, time_format = '%d.%m.%Y %H:%M:%S')
      @dirpath = dirpath
      @pathname = dirpath.join(filename)
      @level = level
      @time_format = time_format
      @mutex = Mutex.new
      
      unless @pathname.exist?
        unless @dirpath.directory?
          FileUtils.mkdir_p @dirpath
        end
        
        File.new(@pathname, 'w+')
      end
      
      @file = File.open(@pathname, 'a+')
      @file.sync = true
    end
    
    def debug(*messages)
      write DEBUG, *messages
    end
    
    def info(*messages)
      write INFO, *messages
    end
    
    def warn(*messages)
      write WARN, *messages
    end
    
    def error(*messages)
      write ERROR, *messages
    end
    
    def fatal(*messages)
      write FATAL, *messages
    end
    
    def unknown(*messages)
      write UNKNOWN, *messages
    end
    
    private
    
    def write(severity, *messages)
      raise(ArgumentError, 'Need a message') if messages.empty?
      raise ArgumentError, 'Need messages that respond to #to_s' if messages.any? { |message| !message.respond_to?(:to_s) }
      
      begin
        if severity >= @level
          @mutex.synchronize do
            messages.each do |message|
              @file.puts "#{LEVEL[severity]} #{Time.now.strftime(@time_format)} #{message}"
            end
          end
        end
      rescue => e
        puts e.message, *e.backtrace
      end
    end
  end
end
