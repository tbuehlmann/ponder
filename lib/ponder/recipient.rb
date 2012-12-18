module Ponder
  class Recipient
    def initialize(nick_or_name, thaum)
      @thaum = thaum
      @mutex = Mutex.new
    end

    private

    def synchronize
      @mutex.synchronize do
        yield
      end
    end

    def raw(message)
      @thaum.connection.send_data "#{message}\r\n"
      @thaum.loggers.info ">> #{message}"
      message
    end
  end
end
