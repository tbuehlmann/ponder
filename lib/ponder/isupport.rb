module Ponder
  class ISupport < Hash
    def initialize
      super

      # Defaults:
      self['CASEMAPPING'] = 'rfc1459'
      self['CHANLIMIT'] = {}
      self['CHANMODES'] = {
        'A' => ['b'],
        'B' => ['k'],
        'C' => ['l'],
        'D' => %w(i m n p s t r)
      }
      self['CHANNELLEN'] = 200
      self['CHANTYPES'] = ['#', '&']
      self['EXCEPTS'] = false
      self['IDCHAN'] = {}
      self['INVEX'] = false
      self['KICKLEN'] = Float::INFINITY
      self['MAXLIST'] = {}
      self['MODES'] = 3
      self['NETWORK'] = ''
      self['NICKLEN'] = Float::INFINITY
      self['PREFIX'] = {'o' => '@', 'v' => '+'}
      self['SAFELIST'] = false
      self['STATUSMSG'] = false
      self['STD'] = false
      self['TARGMAX'] = {}
      self['TOPICLEN'] = Float::INFINITY
    end

    def parse(message)
      patterns = message.split(' ')
      patterns.delete_at(0)
      patterns.each do |pattern|
        return self if pattern.start_with?(':')
        key = pattern.scan(/\w+/).first
        method_name = "set_#{key.downcase}"
        begin
          if respond_to?(method_name, true)
            send method_name, pattern
          else
            set_different key, pattern
          end
        rescue
        end
      end
    end

    private

    def set_casemapping(pattern)
      self['CASEMAPPING'] = pattern.split('=')[1]
    end

    def set_chanlimit(pattern)
      value = pattern.split('=')[1]
      value.split(',').each do |prefixes_and_limit|
        prefixes, limit = prefixes_and_limit.split(':')
        limit = limit.nil? ? Float::INFINITY : limit.to_i
        prefixes.split('').each do |prefix|
          self['CHANLIMIT'][prefix] = limit
        end
      end
    end

    def set_chanmodes(pattern)
      value = pattern.split('=')[1]
      modes_per_type = value.split(',').map { |modes| modes.split('') }
      ('A'..'D').each_with_index do |type, index|
        self['CHANMODES'][type] = modes_per_type[index]
      end
    end

    def set_channellen(pattern)
      self['CHANNELLEN'] = pattern.split('=')[1].to_i
    end

    def set_chantypes(pattern)
      self['CHANTYPES'] = pattern.split('=')[1].split('')
    end

    def set_excepts(pattern)
      mode_char = pattern.split('=')[1]
      self['EXCEPTS'] = mode_char.nil? ? true : mode_char
    end

    def set_idchan(pattern)
      value = pattern.split('=')[1]
      value.split(',').each do |prefix_and_number|
        prefix, number = prefix_and_number.split(':')
        self['IDCHAN'][prefix] = number.to_i
      end
    end

    def set_invex(pattern)
      mode_char = pattern.split('=')[1]
      self['INVEX'] = mode_char.nil? ? true : mode_char
    end

    def set_kicklen(pattern)
      self['KICKLEN'] = pattern.split('=')[1].to_i
    end

    def set_maxlist(pattern)
      value = pattern.split('=')[1]
      value.split(',').each do |prefixes_and_maximum|
        prefixes, maximum = prefixes_and_maximum.split(':')
        prefixes.split('').each do |prefix|
          self['MAXLIST'][prefix] = maximum.to_i
        end
      end
    end

    def set_modes(pattern)
      mode_char = pattern.split('=')[1]
      self['MODES'] = mode_char.nil? ? Float::INFINITY : mode_char.to_i
    end

    def set_network(pattern)
      self['NETWORK'] = pattern.split('=')[1]
    end

    def set_nicklen(pattern)
      self['NICKLEN'] = pattern.split('=')[1].to_i
    end

    def set_prefix(pattern)
      modes, prefixes = pattern.scan(/\((.+)\)(.+)/).flatten
      modes = modes.split('')
      prefixes = prefixes.split('')
      modes.zip(prefixes).each do |pair|
        self['PREFIX'][pair.first] = pair.last
      end
    end

    def set_safelist(pattern)
      self['SAFELIST'] = true
    end

    def set_statusmsg(pattern)
      self['STATUSMSG'] = pattern.split('=')[1].split('')
    end

    def set_std(pattern)
      self['STD'] = pattern.split('=')[1].split(',')
    end

    def set_targmax(pattern)
      targets = pattern.split('=')[1].split(',')
      targets.each do |target_with_maximum|
        target, maximum = target_with_maximum.split(':')
        maximum = maximum.nil? ? Float::INFINITY : maximum.to_i
        self['TARGMAX'][target] = maximum
      end
    end

    def set_topiclen(pattern)
      self['TOPICLEN'] = pattern.split('=')[1].to_i
    end

    def set_different(key, pattern)
      if pattern.include? '='
        if pattern.include? ','
          self[key] = pattern.split('=')[1].split(',')
        else
          self[key] = pattern.split('=')[1]
        end
      else
        self[key] = true
      end
    end
  end
end
