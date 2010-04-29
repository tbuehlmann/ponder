require 'eventmachine'

module Ponder
  class Connection < EventMachine::Connection
    include EventMachine::Protocols::LineText2
    
    def initialize(thaum)
      @thaum = thaum
    end
    
    def connection_completed
      @thaum.register
    end
    
    def unbind
      @thaum.connected = false
      @thaum.traffic_logger.info '-- Ponder disconnected'
      @thaum.console_logger.info '-- Ponder disconnected'
      
      if @thaum.config.reconnect
        @thaum.traffic_logger.info "-- Reconnecting in #{@thaum.config.reconnect_interval} seconds"
        @thaum.console_logger.info "-- Reconnecting in #{@thaum.config.reconnect_interval} seconds"
        
        EventMachine::add_timer(@thaum.config.reconnect_interval) do
          reconnect @thaum.config.server, @thaum.config.port
        end
      else
        EventMachine::stop_event_loop
      end
    end
    
    def receive_line(line)
      @thaum.parse line.force_encoding('utf-8')
    end
  end
end
