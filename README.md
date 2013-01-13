# Ponder [![Gem Version](https://badge.fury.io/rb/ponder.png)](http://badge.fury.io/rb/ponder) [![Build Status](https://travis-ci.org/tbuehlmann/ponder.png)](https://travis-ci.org/tbuehlmann/ponder)

## Description

Ponder (Stibbons) is a Domain Specific Language for writing IRC Bots using the [EventMachine](httpS://github.com/eventmachine/eventmachine "EventMachine") library.

## Requirements
* Ruby >= 1.9.2
* EventMachine >= 0.12.10

## Wiki
Detailed information about using Ponder can be found in the [Project Wiki](https://github.com/tbuehlmann/ponder/wiki).

## Quick Start

### Installation
    gem install ponder

### Usage

#### Setting up the Thaum
    require 'ponder'

    @thaum = Ponder::Thaum.new do |config|
      config.nick   = 'Ponder'
      config.server = 'chat.freenode.org'
      config.port   = 6667
    end

#### Add Event Handling
    @thaum.on :connect do
      @thaum.join '#ponder'
    end

    @thaum.on :channel, /foo/ do |event_data|
      @thaum.message event_data[:channel], 'bar!'
    end

#### Starting the Thaum
    @thaum.connect

## Discworld Context
So, why all that silly names? Ponder Stibbons? Thaum? Twoflogger (referring to Twoflower), BlindIo? What's the Mended Drum? Who's the Librarian? Simply put, I freaking enshrine Terry Pratchett's Discworld Novels and there were no better name for this project than Ponder. Ponder Stibbons is the Head of Inadvisably Applied Magic at the Unseen University of Ankh Morpork. He researched the Thaum, like the atom, just for magic. I just love that character, so there we are. If you're a fan too or want to talk about the Discworld, the framework, whatever, don't hesitate to contact me.

## License

Copyright (c) 2010, 2011, 2012, 2013 Tobias Bühlmann

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
