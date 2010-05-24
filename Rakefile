require 'pathname'

task :test do
  require Pathname.new(__FILE__).dirname.join('test', 'all_tests.rb').expand_path
end

task :default => :test
