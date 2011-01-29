Gem::Specification.new do |s|
  s.name = 'ponder'
  s.version = '0.0.2'
  s.summary = 'IRC bot framework'
  s.description = 'Ponder (Stibbons) is a Domain Specific Language for writing IRC Bots using the EventMachine library.'
  
  s.author = 'Tobias Bühlmann'
  s.email = 'tobias.buehlmann@gmx.de'
  s.homepage = 'http://github.com/tbuehlmann/ponder'
  
  s.required_ruby_version = '>= 1.8.6'
  s.add_dependency('eventmachine', '>= 0.12.10')
  s.files = %w[
    LICENSE
    README.md
    Rakefile
    examples/echo.rb
    examples/github_blog.rb
    examples/redis_last_seen.rb
    lib/ponder.rb
    lib/ponder/async_irc.rb
    lib/ponder/callback.rb
    lib/ponder/connection.rb
    lib/ponder/filter.rb
    lib/ponder/formatting.rb
    lib/ponder/irc.rb
    lib/ponder/logger/blind_io.rb
    lib/ponder/logger/twoflogger.rb
    lib/ponder/thaum.rb
    lib/ponder/version.rb
    ponder.gemspec
    test/test_async_irc.rb
    test/test_callback.rb
    test/test_helper.rb
    test/test_irc.rb
  ]
end

