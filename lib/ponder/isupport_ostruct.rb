require 'ostruct'

module Ponder
  class ISupport < OpenStruct
    def initialize
      super

      # Defaults:
      self.casemapping = 'rfc1459'
      self.chanlimit = {}
      self.chanmodes = {
        'A' => ['b'],
        'B' => ['k'],
        'C' => ['l'],
        'D' => %w(i m n p s t r)
      }
      self.channellen = 200
      self.chantypes = ['#', '&']
      self.excepts = false
      self.idchan = {}
      self.invex = false
      self.kicklen = Float::INFINITY
      self.maxlist = {}
      self.modes = 3
      self.network = ''
      self.nicklen = Float::INFINITY
      self.prefix = {'o' => '@', 'v' => '+'}
      self.safelist = false
      self.statusmsg = false
      self.std = false
      self.targmax = {}
      self.topiclen = Float::INFINITY
    end

    def parse(message)
      patterns = message.split(' ')
      patterns.delete_at(0)
      patterns.each do |pattern|
        return self if pattern.start_with?(':')
        key = pattern.scan(/\w+/).first.downcase
        begin
          method_name = "set_#{key}"
          if respond_to?(method_name, true)
            send method_name, pattern
          else
            set_different key, pattern
          end
        rescue
          puts 'Error!' # TODO: Something useful. Warning?
        end
      end
    end

    private

    def set_casemapping(pattern)
      self.casemapping = pattern.split('=')[1]
    end

    def set_chanlimit(pattern)
      value = pattern.split('=')[1]
      value.split(',').each do |prefixes_and_limit|
        prefixes, limit = prefixes_and_limit.split(':')
        limit = limit.nil? ? Float::INFINITY : limit.to_i
        prefixes.split('').each do |prefix|
          self.chanlimit[prefix] = limit
        end
      end
    end

    def set_chanmodes(pattern)
      value = pattern.split('=')[1]
      modes_per_type = value.split(',').map { |modes| modes.split('') }
      ('A'..'D').each_with_index do |type, index|
        self.chanmodes[type] = modes_per_type[index]
      end
    end

    def set_channellen(pattern)
      self.channellen = pattern.split('=')[1].to_i
    end

    def set_chantypes(pattern)
      self.chantypes = pattern.split('=')[1].split('')
    end

    def set_excepts(pattern)
      mode_char = pattern.split('=')[1]
      self.excepts = mode_char.nil? ? true : mode_char
    end

    def set_idchan(pattern)
      value = pattern.split('=')[1]
      value.split(',').each do |prefix_and_number|
        prefix, number = prefix_and_number.split(':')
        self.idchan[prefix] = number.to_i
      end
    end

    def set_invex(pattern)
      mode_char = pattern.split('=')[1]
      self.invex = mode_char.nil? ? true : mode_char
    end

    def set_kicklen(pattern)
      self.kicklen = pattern.split('=')[1].to_i
    end

    def set_maxlist(pattern)
      value = pattern.split('=')[1]
      value.split(',').each do |prefixes_and_maximum|
        prefixes, maximum = prefixes_and_maximum.split(':')
        prefixes.split('').each do |prefix|
          self.maxlist[prefix] = maximum.to_i
        end
      end
    end

    def set_modes(pattern)
      mode_char = pattern.split('=')[1]
      self.modes = mode_char.nil? ? Float::INFINITY : mode_char.to_i
    end

    def set_network(pattern)
      self.network = pattern.split('=')[1]
    end

    def set_nicklen(pattern)
      self.nicklen = pattern.split('=')[1].to_i
    end

    def set_prefix(pattern)
      modes, prefixes = pattern.scan(/\((.+)\)(.+)/).flatten
      modes = modes.split('')
      prefixes = prefixes.split('')
      modes.zip(prefixes).each do |pair|
        self.prefix[pair.first] = pair.last
      end
    end

    def set_safelist(pattern)
      self.safelist = true
    end

    def set_statusmsg(pattern)
      self.statusmsg = pattern.split('=')[1].split('')
    end

    def set_std(pattern)
      self.std = pattern.split('=')[1].split(',')
    end

    def set_targmax(pattern)
      targets = pattern.split('=')[1].split(',')
      targets.each do |target_with_maximum|
        target, maximum = target_with_maximum.split(':')
        maximum = maximum.nil? ? Float::INFINITY : maximum.to_i
        self.targmax[target] = maximum
      end
    end

    def set_topiclen(pattern)
      self.topiclen = pattern.split('=')[1].to_i
    end

    def set_different(key, pattern)
      if pattern.include? '='
        if pattern.include? ','
          send "#{key}=", pattern.split('=')[1].split(',')
        else
          send "#{key}=", pattern.split('=')[1]
        end
      else
        send "#{key}=", true
      end
    end
  end
end
