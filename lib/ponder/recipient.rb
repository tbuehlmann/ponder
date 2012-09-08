module Ponder
  class Recipient
  	def initialize(nick_or_name, thaum)
      @thaum = thaum
      @mutex = Mutex.new
    end

    private

    def raw(message)
      @thaum.connection.send_data "#{message}\r\n"
      @thaum.logger.info ">> #{message}"
      @thaum.console_logger.info ">> #{message}"
      message
    end
  end
end
