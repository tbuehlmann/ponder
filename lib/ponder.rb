require 'pathname'
require 'rubygems'

$LOAD_PATH.unshift Pathname.new(__FILE__).dirname.expand_path

module Ponder
  def self.root
    Pathname.new($0).dirname.expand_path
  end
  
  require 'ponder/version'
  require 'ponder/thaum'
  require 'ponder/formatting'
end

