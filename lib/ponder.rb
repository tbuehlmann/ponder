$LOAD_PATH.unshift(File.dirname(__FILE__))

module Ponder
  def self.root
    Pathname.new($0).dirname.expand_path
  end
  
  require 'ponder/version'
  require 'ponder/thaum'
  require 'ponder/formatting'
end

