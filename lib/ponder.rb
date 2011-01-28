$LOAD_PATH.unshift(File.dirname(__FILE__))

module Ponder
  ROOT = File.dirname($0)

  autoload :Filter,     'ponder/filter'
  autoload :Formatting, 'ponder/formatting'
  autoload :Thaum,      'ponder/thaum'
  autoload :VERSION,    'ponder/version'
end

