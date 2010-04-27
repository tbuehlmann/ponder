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
end
