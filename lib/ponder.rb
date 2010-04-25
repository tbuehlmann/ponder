require 'pathname'
$LOAD_PATH.unshift Pathname(__FILE__).dirname.expand_path

Object::const_set(:PONDER_ROOT, Pathname($0).dirname.expand_path)

require 'ponder/version'
require 'ponder/thaum'
require 'ponder/formatting'
