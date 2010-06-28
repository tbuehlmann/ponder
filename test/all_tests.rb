require 'pathname'
$LOAD_PATH.unshift Pathname.new(__FILE__).dirname.expand_path

require 'test_callback'
require 'test_async_irc'
require 'test_irc'

