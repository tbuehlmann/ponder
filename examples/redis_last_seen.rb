# This Thaum remembers users' actions and is able to quote them.
# Go for it with `!seen <nick>`. You can even use wildcards with "*".
# 
# The redis server version needs to be >= 1.3.10 for hash support.

$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))

require 'rubygems'
require 'ponder'
require 'redis'

FORMAT = '%Y-%m-%d %H:%M:%S'

class String
  def escape_redis
    self.gsub(/([\|\[\]\?])/, '\\\\\1')
  end
end

@redis = Redis.new(:thread_safe => true)

def remember(lowercase_nick, nick, user, host, channel, action,
               action_content)
  @redis.hmset(
    lowercase_nick,
    'nick',           nick,
    'user',           user,
    'host',           host,
    'channel',        channel,
    'action',         action,
    'action_content', action_content,
    'updated_at',     Time.now.to_i)
end

@ponder = Ponder::Thaum.new

@ponder.configure do |c|
  c.server  = 'chat.freenode.org'
  c.port    = 6667
  c.nick    = 'Ponder'
  c.verbose = true
  c.logging = false
end

@ponder.on :connect do
  @ponder.join '#ponder'
end

@ponder.on :channel do |event_data|
  remember(event_data[:nick].downcase, event_data[:nick], event_data[:user],
             event_data[:host], event_data[:channel], event_data[:type],
             event_data[:message])
end

@ponder.on [:join, :part, :quit] do |event_data|
  remember(event_data[:nick].downcase, event_data[:nick], event_data[:user],
             event_data[:host], event_data[:channel], event_data[:type],
             (event_data[:message] || event_data[:channel]))
end

@ponder.on :nickchange do |event_data|
  remember(event_data[:nick].downcase, event_data[:nick], event_data[:user],
             event_data[:host], '', 'nickchange_old', event_data[:new_nick])
  
  remember(event_data[:new_nick].downcase, event_data[:new_nick],
             event_data[:user], event_data[:host], '', 'nickchange_new', 
             event_data[:nick])
end

@ponder.on :kick do |event_data|
  remember(event_data[:nick].downcase, event_data[:nick], event_data[:user],
             event_data[:host], event_data[:channel], 'kicker',
              "#{event_data[:victim]} #{event_data[:reason]}")
  
  remember(event_data[:victim].downcase, event_data[:victim],
             '', '', event_data[:channel], 'victim', 
             "#{event_data[:nick]} #{event_data[:reason]}")
end

def last_seen(nick)
  data = @redis.hgetall(nick)

  case data['action']
  when 'channel'
    "#{data['nick']} wrote something in #{data['channel']} at #{Time.at(data['updated_at'].to_i).strftime(FORMAT)}."
  when 'join'
    "#{data['nick']} joined #{data['channel']} at #{Time.at(data['updated_at'].to_i).strftime(FORMAT)}."
  when 'part'
    "#{data['nick']} left #{data['channel']} at #{Time.at(data['updated_at'].to_i).strftime(FORMAT)} (#{data['action_content']})."
  when 'quit'
    "#{data['nick']} quit at #{Time.at(data['updated_at'].to_i).strftime(FORMAT)} (#{data['action_content']})."
  when 'nickchange_old'
    "#{data['nick']} renamed to #{data['action_content']}} at #{Time.at(data['updated_at'].to_i).strftime(FORMAT)}."
  when 'nickchange_new'
    "#{data['nick']} renamed to #{data['action_content']} at #{Time.at(data['updated_at'].to_i).strftime(FORMAT)}."
  when 'kicker'
    "#{data['nick']} kicked #{data['action_content'].split(' ')[0]} at #{Time.at(data['updated_at'].to_i).strftime(FORMAT)} from #{data['channel']} (#{data['action_content'].split(' ')[1]})."
  when 'victim'
    "#{data['nick']} was kicked by #{data['action_content'].split(' ')[0]} at #{Time.at(data['updated_at'].to_i).strftime(FORMAT)} from #{data['channel']} (#{data['action_content'].split(' ')[1]})."
  end
end

@ponder.on :channel, /^!seen \S+$/ do |event_data|
  nick = event_data[:message].split(' ')[1].downcase

  # wildcards
  if nick =~ /\*/
    users = @redis.keys nick.escape_redis
    results = users.length

    case results
    when 0
      @ponder.message event_data[:channel], 'No such nick found.'
    when 1
      @ponder.message event_data[:channel], last_seen(users[0])
    when 2..5
      nicks = []
      users.each do |user|
        nicks << @redis.hgetall(user)['nick']
      end
      nicks = nicks.join(', ')
      @ponder.message event_data[:channel], "#{results} nicks found (#{nicks})."
    else
      @ponder.message event_data[:channel], "Too many results (#{results})."
    end
  # single search
  elsif @redis.exists nick
    msg = last_seen(nick)
    if online_nick = @ponder.whois(nick)
      msg = "#{online_nick[:nick]} is online. (#{msg})"
    end
    @ponder.message event_data[:channel], msg
  elsif online_nick = @ponder.whois(nick)
    @ponder.message event_data[:channel], "#{online_nick[:nick]} is online."
  else
    @ponder.message event_data[:channel], "#{nick} not found."
  end
end

@ponder.connect

