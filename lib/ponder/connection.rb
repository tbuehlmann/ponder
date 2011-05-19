require 'rubygems'
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
      @thaum.process_callbacks :disconnect, {}
      @thaum.logger.info '-- Ponder disconnected'
      @thaum.console_logger.info '-- Ponder disconnected'

      if @thaum.config.reconnect
        @thaum.logger.info "-- Reconnecting in #{@thaum.config.reconnect_interval} seconds"
        @thaum.console_logger.info "-- Reconnecting in #{@thaum.config.reconnect_interval} seconds"

        EventMachine::add_timer(@thaum.config.reconnect_interval) do
          reconnect @thaum.config.server, @thaum.config.port
        end
      else
        @thaum.logger.close
        @thaum.console_logger.close
      end
    end

    def receive_line(line)
      @thaum.parse line
    end
  end
end

