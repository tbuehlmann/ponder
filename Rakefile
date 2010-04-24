require 'pathname'

task :test do
  require Pathname(__FILE__).dirname.join('test', 'all_tests.rb').expand_path
end

task :default => :test
