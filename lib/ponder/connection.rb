module Ponder
  class Connection < EventMachine::Connection
    include EventMachine::Protocols::LineText2

    def initialize(thaum)
      @thaum = thaum
    end

    def connection_completed
      @thaum.register
    end

    def post_init
      start_tls if @thaum.config.ssl
    end

    def unbind
      @thaum.connected = false
      @thaum.process_callbacks :disconnect, {}
      @thaum.loggers.info '-- Ponder disconnected'

      if @thaum.config.reconnect
        @thaum.loggers.info "-- Reconnecting in #{@thaum.config.reconnect_interval} seconds"

        EventMachine::add_timer(@thaum.config.reconnect_interval) do
          reconnect @thaum.config.server, @thaum.config.port
        end
      else
        @thaum.loggers.close
      end
    end

    def receive_line(line)
      @thaum.parse line
    end
  end
end
