$LOAD_PATH.unshift(File.dirname(__FILE__))

require 'test_helper'
require 'ponder/thaum'

class TestIRC < Test::Unit::TestCase
  def setup
    @ponder = Ponder::Thaum.new

    @ponder.configure do |c|
      c.nick      = 'Ponder'
      c.username  = 'Ponder'
      c.real_name  = 'Ponder Stibbons'
      c.password  = 'secret'
      c.reconnect = true
    end

    def @ponder.raw(message)
      $output << "#{message}\r\n"
      return "#{message}\r\n"
    end

    $output = []
  end

  def test_message
    assert_equal("PRIVMSG recipient :foo bar baz\r\n", @ponder.message('recipient', 'foo bar baz'))
  end

  def test_register
    @ponder.register

    assert_equal(["NICK Ponder\r\n", "USER Ponder * * :Ponder Stibbons\r\n", "PASS secret\r\n"], $output)
  end

  def test_register_without_password
    @ponder.configure { |c| c.password = nil }

    @ponder.register

    assert_equal(["NICK Ponder\r\n", "USER Ponder * * :Ponder Stibbons\r\n"], $output)
  end

  def test_notice
    assert_equal("NOTICE Ponder :You are cool!\r\n", @ponder.notice('Ponder', 'You are cool!'))
  end

  def test_mode
    assert_equal("MODE Ponder +ao\r\n", @ponder.mode('Ponder', '+ao'))
  end

  def test_kick
    assert_equal("KICK #channel Nanny_Ogg\r\n", @ponder.kick('#channel', 'Nanny_Ogg'))
  end

  def test_kick_with_reason
    assert_equal("KICK #channel Nanny_Ogg :Go away!\r\n", @ponder.kick('#channel', 'Nanny_Ogg', 'Go away!'))
  end

  def test_action
    assert_equal("PRIVMSG #channel :\001ACTION HEX is working!\001\r\n", @ponder.action('#channel', 'HEX is working!'))
  end

  def test_topic
    assert_equal("TOPIC #channel :I like dried frog pills.\r\n", @ponder.topic('#channel', 'I like dried frog pills.'))
  end

  def test_join
    assert_equal("JOIN #channel\r\n", @ponder.join('#channel'))
  end

  def test_join_with_password
    assert_equal("JOIN #channel secret\r\n", @ponder.join('#channel', 'secret'))
  end

  def test_part
    assert_equal("PART #channel\r\n", @ponder.part('#channel'))
  end

  def test_part_with_message
    assert_equal("PART #channel :Partpart\r\n", @ponder.part('#channel', 'Partpart'))
  end

  def test_quit

    @ponder.quit

    assert_equal(["QUIT\r\n"], $output)
  end

  def test_quit_with_message
    @ponder.quit('GONE')

    assert_equal(["QUIT :GONE\r\n"], $output)
  end

  def test_quit_reconnect_change
    assert_equal(true, @ponder.config.reconnect)

    @ponder.quit

    assert_equal(false, @ponder.config.reconnect)
  end

  def test_rename
    assert_equal("NICK :Ridcully\r\n", @ponder.rename('Ridcully'))
  end

  def test_away
    assert_equal("AWAY\r\n", @ponder.away)
  end

  def test_away_with_message
    assert_equal("AWAY :At the Mended Drum\r\n", @ponder.away('At the Mended Drum'))
  end

  def test_back
    assert_equal("AWAY\r\n", @ponder.back)
  end

  def test_invite
    assert_equal("INVITE TheLibrarian #mended_drum\r\n", @ponder.invite('TheLibrarian', '#mended_drum'))
  end

  def test_ban
    assert_equal("MODE #mended_drum +b foo!bar@baz\r\n", @ponder.ban('#mended_drum', 'foo!bar@baz'))
  end
end

