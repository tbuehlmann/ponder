require 'pathname'
require 'rubygems'
require 'bundler'
Bundler.setup

$LOAD_PATH.unshift Pathname(__FILE__).dirname.expand_path

module Ponder
  def self.root
    Pathname($0).dirname.expand_path
  end
  
  require 'ponder/version'
  require 'ponder/thaum'
  require 'ponder/formatting'
  require 'ponder/logger/blind_io'
  
  if RUBY_VERSION < '1.9'
    require 'ruby/1.8/string'
    require 'ponder/logger/twoflogger18'
  else
    require 'ponder/logger/twoflogger'
  end
end
