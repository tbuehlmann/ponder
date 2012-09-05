# Ponder

## Description
Ponder (Stibbons) is a Domain Specific Language for writing IRC Bots using the [EventMachine](http://github.com/eventmachine/eventmachine "EventMachine") library.

## Requirements
* Ruby >= 1.9.1
* EventMachine >= 0.12.10

## Getting started
### Installation
    $ sudo gem install ponder

### Configuring the Bot (Thaum!)
    require 'rubygems'
    require 'ponder'
    
    @thaum = Ponder::Thaum.new do |thaum|
      thaum.nick   = 'Ponder'
      thaum.server = 'irc.freenode.net'
      thaum.port   = 6667
    end

### Starting the Thaum
    @thaum.connect

### Event Handling
This naked Thaum will connect to the server and answer PING requests (and VERSION and TIME). If you want the Thaum to join a channel when it's connected, use the following:

    @thaum.on :connect do
      @thaum.join '#mended_drum'
    end

If you want the Thaum to answer on specific channel messages, register this Event Handler:

    @thaum.on :channel, /ponder/ do |event_data|
      @thaum.message event_data[:channel], 'Heard my name!'
    end

Now, if an incoming channel message contains the word "ponder", the Thaum will send the message "Heard my name!" to that specific channel. See the **Advanced Event Handling** chapter for more details on how to register Event Handlers and the `event_data` hash. For more examples, have a look at the examples directory.

## Advanced Configuration
Besides the configuration for nick, server and port as shown in the **Getting Started** chapter, there are some more preferences Ponder accepts. All of them:

* `server`

    The `server` variable describes the server the Thaum shall connect to. It defaults to `'localhost'`.

* `port`

    `port` describes the port that is used for the connection. It defaults to `6667`.

* `ssl`

    If `ssl` is set to `true`, the Thaum will connect to the server using SSL. It defaults to `false`.

* `nick`

    `nick` describes the nick the Thaum will try to register when connecting to the server. It will not be updated if the Thaum changes its nick. It defaults to `'Ponder'`.

* `username`

    `username` is used for describing the username. It defaults to `'Ponder'`.

* `real_name`

    `real_name` is used for describing the real name. It defaults to `'Ponder'`.

* `verbose`

    If `verbose` is set to `true`, all incoming and outgoing traffic will be put to the console. Plus exceptions raised in Callbacks (errors). It defaults to `true`.

* `logging`

    If `logging` is set to `true`, all incoming and outgoing traffic and exceptions will be logged to logs/log.log.
    
    You can also define your own logger, using `thaum.logger = @my_cool_logger` or `thaum.logger = Logger.new(...)`. Ponder itself just uses the #info, #error and #close method on the logger.
    
    You can access the logger instance via `@thaum.logger`, so you could do: `@thaum.logger.info('I did this and that right now')`.
    
    It defaults to `false`.

* `reconnect`

    If `reconnect` is set to `true`, the Thaum will try to reconnect after being disconnected from the server (netsplit, ...). It will not try to reconnect if you call `quit` on the Thaum. It defaults to `true`.

* `reconnect_interval`

    If `reconnect` is set to `true`, `reconnect_interval` describes the time in seconds, which the Thaum will wait before trying to reconnect. It defaults to `30`.

For further information, have a look at the examples.

## Advanced Event Handling
A Thaum can react on several events, so here is a list of handlers that can be used as argument in the `on` method:

* `join`

    The `join` handler reacts, if an user joins a channel in which the Thaum is in. Example:
    
        @thaum.on :join do
          # ...
        end
        
    If using a block variable, you have access to a hash with detailed information about the event. Example:
    
        @thaum.on :join do |event_data|
          @thaum.message event_data[:channel], "Hello #{event_data[:nick]}! Welcome to #{event_data[:channel]}."
        end
    
    Which will greet a joined user with a channel message.
    
    The hash contains data for the keys `:nick`, `:user`, `:host` and `:channel`.

* `part`

    Similar to the `join` handler but reacts on parting users. The block variable hash contains data for the keys `:nick`, `:user`, `:host`, `:channel` and `:message`. The value for `:message` is the message the parting user leaves.

* `quit`

    The `quit` handler reacts, if an user quits from the server (and the Thaum can see it in a channel). The block variable hash contains data for the keys `:nick`, `:user`, `:host` and `:message`.

* `channel`

    If an user sends a message to a channel, you can react with the `channel` handler. Example (from above):
    
        @thaum.on :channel, /ponder/ do |event_data|
          @thaum.message event_data[:channel], 'Heard my name!'
        end
    
    The block variable hash contains data for the keys `:nick`, `:user`, `:host`, `:channel` and `:message`.

* `query`

    The `query` handler is like the `channel` handler, but for queries. Same keys in the data hash but no `:channel`.

* `nickchange`

    `nickchange` reacts on nickchanges. Data hash keys are `:nick`, `:user`, `:host` and `:new_nick`, where `nick` is the nick before renaming and `new_nick` the nick after renaming.

* `kick`

    If an user is being kicked, the `kick` handler can handle that event. Data hash keys are: `:nick`, `:user`, `:host`, `:channel`, `:victim` and `:reason`.

* `topic`

    `topic` is for reacting on topic changes. Data hash keys are: `:nick`, `:user`, `:host`, `:channel` and `:topic`, where `:topic` is the new topic. You can provide a Regexp to just react on specific patterns:
    
        @thaum.on :topic, /foo/ do |event_data|
          # ...
        end
    
    This will just work for topics that include the word "foo".

* `disconnect`

    `disconnect` reacts on being disconnected from the server (netsplit, quit, ...). It does not react if you exit the program with ^C.

* Raw numerics

    A Thaum can seperately react on events with raw numerics, too. So you could do:
    
        @thaum.on 301 do |event_data|
          # ...
        end
    
    The data hash will contain the `:params` key. The corresponding value is the complete traffic line that came in.

For all Event Handlers there is a `:type` key in the data hash (if the variable is specified). Its value gives the type of event, like `:channel`, `:join` or `301`.

## Commanding the Thaum
Command the Thaum, very simple. Just call a method listed below on the Ponder object. I will keep this short, since I assume you're at least little experienced with IRC.

* `message(recipient, message)`
* `notice(recipient, message)`
* `mode(recipient, option)`
* `kick(channel, user, reason = nil)`
* `action(recipient, message)`
* `topic(channel, topic)`
* `join(channel, password = nil)`
* `part(channel, message = nil)`
* `quit(message = nil)`
* `rename(nick)`
* `away(message = nil)`
* `back`
* `invite(nick, channel)`
* `ban(channel, address)`

Last but not least some cool "give me something back" methods:

* `get_topic(channel)`

    * Possible return values for `get_topic` are:
    
        * `{:raw_numeric => 331, :message => 'No topic is set'}` if no topic is set
        * `{:raw_numeric => 332, :message => message}` with `message` the topic message
        * `{:raw_numeric => 403, :message => 'No such channel'}` if there is no such channel
        * `{:raw_numeric => 442, :message => "You're not on that channel"}` if you cannot actually see the topic
        * `false` if the request times out (30 seconds)

* `channel_info(channel)`

    * Possible return values:
    
        * If successful, a hash with keys:
        
            * `:modes` (letters)
            * `:channel_limit` (if channel limit is set)
            * `:created_at` (Time object of the time the channel was created)
            
        * `false`, if the request is not successful or times out (30 seconds)

* `whois(nick)`

    * Possible return values:
    
        * If successful, a hash with keys:
        
            * `:nick`
            * `:username`
            * `:host`
            * `:real_name`
            * `:server` (a hash with the keys `:address` and `:name`)
            * `:channels` (a hash like `{'#foo' => '@', '#bar' => nil}` where the values are user privileges)
            * `:registered` (`true`, if registered, else `nil`)
            
        * If not successful
        
            * `false`
            
        * If times out (30 seconds)
        
            * `nil`
    
    Example:
    
        # Ponder, kick an user (and check if I'm allowed to command you)!
        @thaum.on :channel, /^!kick \S+$/ do |event_data|
          user_data = @thaum.whois(event_data[:nick])
          if user_data[:registered] && (user_data[:channels][event_data[:channel]] == '@')
            user_to_kick = event_data[:message].split(' ')[1]
            @thaum.kick event_data[:channel], user_to_kick, 'GO!'
          end
        end

## Timers
If you need something in an event handling process to be time-displaced, you should not use `sleep`. I recommend using the comfortable timer methods EventMachine provides. A one shot timer looks like this:

    EventMachine::Timer.new(10) do
      # code to be run after 10 seconds
    end

If you want the timer to be canceled before starting, you can do it like this:

    timer = EventMachine::Timer.new(10) do
      # code to be run after 10 seconds
    end
    
    # ...
    
    timer.cancel

You can even have periodic timers which will fire up every n seconds:

    EventMachine::PeriodicTimer.new(10) do
      # code to be run every 10 seconds
    end

A periodic timer can be canceled just like the other one.

## Formatting
You can format your messages with colors, make it bold, italic or underlined. All of those formatting constants are availabe through `Ponder::Formatting`.

### Colors
For coloring text you first set the color code with `Ponder::Formatting::COLOR_CODE` followed by a color followed by the text. For ending the colored text, set the uncolor code with `Ponder::Formatting::UNCOLOR`.

Availabe colors are white, black, blue, green, red, brown, purple, orange, yellow, lime, teal, cyan, royal, pink, gray and silver. You can set one with the `Ponder::Formatting::COLORS` hash. Example:

    "This will be #{Ponder::Formatting::COLOR_CODE}#{Ponder::Formatting::COLORS[:red]}red#{Ponder::Formatting::UNCOLOR_CODE}. This not."

### Font Styles
If you want to make a text bold, italic or underlined, use `Ponder::Formatting::BOLD`, `Ponder::Formatting::ITALIC` or `Ponder::Formatting::UNDERLINE`. After the text, close it with the same constant. Example:

    "This will be #{Ponder::Formatting::UNDERLINE}underlined#{Ponder::Formatting::UNDERLINE}. This not."

### Shortened Formatting
If you don't always want to use `Ponder::Formatting`, use `include Ponder::Formatting`. All constants will then be availabe without `Ponder::Formatting` in front.

## Source
The source can be found at GitHub: [tbuehlmann/ponder](http://github.com/tbuehlmann/ponder "Ponder").

You can contact me through [GitHub](http://github.com/tbuehlmann/ "GitHub") and IRC (named tbuehlmann in the Freenode network).

## Discworld Context
So, why all that silly names? Ponder Stibbons? Thaum? Twoflogger (referring to Twoflower), BlindIo? What's the Mended Drum? Who's the Librarian? Simply put, I freaking enshrine Terry Pratchett's Discworld Novels and there were no better name for this project than Ponder. Ponder Stibbons is the Head of Inadvisably Applied Magic at the Unseen University of Ankh Morpork. He researched the Thaum, like the atom, just for magic. And I just love that character, so there we are. If you're a fan too or want to talk about the Discworld, the framework, whatever, don't hesitate to contact me.

## License
Copyright (c) 2010, 2011 Tobias Bühlmann

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
