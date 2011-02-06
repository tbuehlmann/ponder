require 'thread'
require 'timeout'

module Ponder
  module AsyncIRC
    TIMEOUT = 30

    def get_topic(channel)
      queue = Queue.new
      @observer_queues[queue] = [/:\S+ (331|332|403|442) \S+ #{Regexp.escape(channel)} :/i]
      raw "TOPIC #{channel}"

      topic = begin
        Timeout::timeout(TIMEOUT) do
          response = queue.pop
          raw_numeric = response.scan(/^:\S+ (\d{3})/)[0][0]

          case raw_numeric
          when '331'
            {:raw_numeric => 331, :message => 'No topic is set'}
          when '332'
            {:raw_numeric => 332, :message => response.scan(/ :(.*)/)[0][0]}
          when '403'
            {:raw_numeric => 403, :message => 'No such channel'}
          when '442'
            {:raw_numeric => 442, :message => "You're not on that channel"}
          end
        end
      rescue Timeout::Error
        false
      end

      @observer_queues.delete queue
      return topic
    end

    def channel_info(channel)
      queue = Queue.new
      @observer_queues[queue] = [/:\S+ (324|329|403|442) \S+ #{Regexp.escape(channel)}/i]
      raw "MODE #{channel}"
      information = {}
      running = true

      begin
        Timeout::timeout(TIMEOUT) do
          while running
            response = queue.pop
            raw_numeric = response.scan(/^:\S+ (\d{3})/)[0][0]

            case raw_numeric
            when '324'
              information[:modes] = response.scan(/^:\S+ 324 \S+ \S+ \+(\w*)/)[0][0].split('')
              limit = response.scan(/^:\S+ 324 \S+ \S+ \+\w* (\w*)/)[0]
              information[:channel_limit] = limit[0].to_i if limit
            when '329'
              information[:created_at] = Time.at(response.scan(/^:\S+ 329 \S+ \S+ (\d+)/)[0][0].to_i)
              running = false
            when '403', '442'
              information = false
              running = false
            end
          end
        end
      rescue Timeout::Error
        information = false
      end

      @observer_queues.delete queue
      return information
    end

    def whois(nick)
      queue = Queue.new
      @observer_queues[queue] = [/^:\S+ (307|311|312|318|319|401) \S+ #{Regexp.escape(nick)}/i]
      raw "WHOIS #{nick}"
      whois = {}
      running = true

      while running
        begin
          Timeout::timeout(TIMEOUT) do
            response = queue.pop
            raw_numeric = response.scan(/^:\S+ (\d{3})/)[0][0]

            case raw_numeric
            when '307'
              whois[:registered] = true
            when '311'
              response = response.scan(/^:\S+ 311 \S+ (\S+) (\S+) (\S+) \* :(.*)$/)[0]
              whois[:nick]      = response[0]
              whois[:username]  = response[1]
              whois[:host]      = response[2]
              whois[:real_name] = response[3]
            when '312'
              response = response.scan(/^:\S+ 312 \S+ \S+ (\S+) :(.*)/)[0]
              whois[:server] = {:address => response[0], :name => response[1]}
            when '318'
              running = false
            when '319'
              channels_with_mode = response.scan(/^:\S+ 319 \S+ \S+ :(.*)/)[0][0].split(' ')
              whois[:channels] = {}
              channels_with_mode.each do |c|
                whois[:channels][c.scan(/(.)?(#\S+)/)[0][1]] = c.scan(/(.)?(#\S+)/)[0][0]
              end
            when '401'
              whois = false
              running = false
            end
          end
        rescue Timeout::Error
          nil
        end
      end

      @observer_queues.delete queue
      return whois
    end
  end
end

