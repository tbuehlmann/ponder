$LOAD_PATH.unshift(File.dirname(__FILE__))

require 'spec_helper'
require 'ponder/isupport'

describe Ponder::ISupport do
  before(:each) do
    @isupport = Ponder::ISupport.new
  end

  describe 'CASEMAPPING' do
    it 'sets CASEMAPPING correctly' do
      @isupport.parse('bot_nick CASEMAPPING=foobar')
      @isupport['CASEMAPPING'].should eq('foobar')
    end
  end

  describe 'CHANLIMIT' do
    it 'sets CHANLIMIT correctly having one argument' do
      @isupport.parse('bot_nick CHANLIMIT=#:120')
      @isupport['CHANLIMIT'].should eq({'#' => 120})
    end

    it 'sets CHANLIMIT correctly having many argument' do
      @isupport.parse('bot_nick CHANLIMIT=#+:10,&')
      @isupport['CHANLIMIT'].should eq({'#' => 10, '+' => 10, '&' => Float::INFINITY})
    end
  end

  describe 'CHANMODES' do
    it 'sets CHANMODES correctly' do
      @isupport.parse('bot_nick CHANMODES=eIbq,k,flj,CFLMPQcgimnprstz')
      @isupport['CHANMODES'].should eq({
        'A' => %w(e I b q),
        'B' => %w(k),
        'C' => %w(f l j),
        'D' => %w(C F L M P Q c g i m n p r s t z)
      })
    end
  end

  describe 'CHANNELLEN' do
    it 'sets CHANNELLEN correctly' do
      @isupport.parse('bot_nick CHANNELLEN=50')
      @isupport['CHANNELLEN'].should eq(50)
    end
  end

  describe 'CHANTYPES' do
    it 'sets CHANTYPES correctly having one type' do
      @isupport.parse('bot_nick CHANTYPES=#')
      @isupport['CHANTYPES'].should eq(['#'])
    end

    it 'sets CHANTYPES correctly having many types' do
      @isupport.parse('bot_nick CHANTYPES=+#&')
      @isupport['CHANTYPES'].should eq(%w(+ # &))
    end
  end

  describe 'EXCEPTS' do
    it 'sets EXCEPTS correctly with mode_char' do
      @isupport.parse('bot_nick EXCEPTS')
      @isupport['EXCEPTS'].should be_true
    end

    it 'sets EXCEPTS correctly without mode_char' do
      @isupport.parse('bot_nick EXCEPTS=e')
      @isupport['EXCEPTS'].should eq('e')
    end
  end

  describe 'IDCHAN' do
    it 'sets IDCHAN correctly having one argument' do
      @isupport.parse('bot_nick IDCHAN=!:5')
      @isupport['IDCHAN'].should eq({'!' => 5})
    end

    it 'sets IDCHAN correctly having many arguments' do
      @isupport.parse('bot_nick IDCHAN=!:5,?:4')
      @isupport['IDCHAN'].should eq({'!' => 5, '?' => 4})
    end
  end

  describe 'INVEX' do
    it 'sets INVEX correctly having no argument' do
      @isupport.parse('bot_nick INVEX')
      @isupport['INVEX'].should be_true
    end

    it 'sets IDCHAN correctly having one argument' do
      @isupport.parse('bot_nick INVEX=a')
      @isupport['INVEX'].should eq('a')
    end
  end

  describe 'KICKLEN' do
    it 'sets KICKLEN correctly' do
      @isupport.parse('bot_nick KICKLEN=100')
      @isupport['KICKLEN'].should eq(100)
    end
  end

  describe 'MAXLIST' do
    it 'sets MAXLIST correctly having one argument' do
      @isupport.parse('bot_nick MAXLIST=b:25')
      @isupport['MAXLIST'].should eq({'b' => 25})
    end

    it 'sets MAXLIST correctly having many arguments' do
      @isupport.parse('bot_nick MAXLIST=b:25,eI:50')
      @isupport['MAXLIST'].should eq({'b' => 25, 'e' => 50, 'I' => 50})
    end
  end

  describe 'MODES' do
    it 'sets MODES correctly having no argument' do
      @isupport.parse('bot_nick MODES')
      @isupport['MODES'].should eq(Float::INFINITY)
    end

    it 'sets MODES correctly having one argument' do
      @isupport.parse('bot_nick MODES=5')
      @isupport['MODES'].should eq(5)
    end
  end

  describe 'NETWORK' do
    it 'sets NETWORK correctly' do
      @isupport.parse('bot_nick NETWORK=freenode')
      @isupport['NETWORK'].should eq('freenode')
    end
  end

  describe 'NICKLEN' do
    it 'sets NICKLEN correctly' do
      @isupport.parse('bot_nick NICKLEN=9')
      @isupport['NICKLEN'].should eq(9)
    end
  end

  describe 'PREFIX' do
    it 'sets PREFIX correctly' do
      @isupport.parse('bot_nick PREFIX=(ohv)@%+')
      @isupport['PREFIX'].should eq({'o' => '@', 'h' => '%', 'v' => '+'})
    end
  end

  describe 'SAFELIST' do
    it 'sets SAFELIST correctly' do
      @isupport.parse('bot_nick SAFELIST')
      @isupport['SAFELIST'].should be_true
    end
  end

  describe 'STATUSMSG' do
    it 'sets STATUSMSG correctly having one argument' do
      @isupport.parse('bot_nick STATUSMSG=+')
      @isupport['STATUSMSG'].should eq(['+'])
    end

    it 'sets STATUSMSG correctly having many arguments' do
      @isupport.parse('bot_nick STATUSMSG=@+')
      @isupport['STATUSMSG'].should eq(['@', '+'])
    end
  end

  describe 'STD' do
    it 'sets STD correctly having one argument' do
      @isupport.parse('bot_nick STD=foo')
      @isupport['STD'].should eq(['foo'])
    end

    it 'sets STD correctly having many arguments' do
      @isupport.parse('bot_nick STD=foo,bar,baz')
      @isupport['STD'].should eq(['foo', 'bar', 'baz'])
    end
  end

  describe 'TARGMAX' do
    it 'sets TARGMAX correctly having limits' do
      @isupport.parse('bot_nick TARGMAX=NAMES:1,LIST:2,KICK:3')
      @isupport['TARGMAX'].should eq({'NAMES' => 1, 'LIST' => 2, 'KICK' => 3})
    end

    it 'sets TARGMAX correctly having limits and no limits' do
      @isupport.parse('bot_nick TARGMAX=NAMES:1,LIST:2,KICK:3,WHOIS:1,PRIVMSG:4,NOTICE:4,ACCEPT:,MONITOR:')
      @isupport['TARGMAX'].should eq({
        'NAMES' => 1,
        'LIST' => 2,
        'KICK' => 3,
        'WHOIS' => 1,
        'PRIVMSG' => 4,
        'NOTICE' => 4,
        'ACCEPT' => Float::INFINITY,
        'MONITOR' => Float::INFINITY
        })
    end
  end

  describe 'TOPICLEN' do
    it 'sets TOPICLEN correctly' do
      @isupport.parse('bot_nick TOPICLEN=250')
      @isupport['TOPICLEN'].should eq(250)
    end
  end

  describe 'Different' do
    it 'sets non mentioned keys correclty aswell' do
      @isupport.parse('bot_nick AWAYLEN=160')
      @isupport.parse('bot_nick CNOTICE')
      @isupport.parse('bot_nick EXTBAN=$,arx')
      @isupport['AWAYLEN'].should eq('160')
      @isupport['CNOTICE'].should be_true
      @isupport['EXTBAN'].should eq(['$', 'arx'])
    end
  end

  describe 'Several arguments at once' do
    it 'sets several arguments at once correcty' do
      @isupport.parse('bot_nick CHANTYPES=# EXCEPTS INVEX CHANMODES=eIbq,k,flj,CFLMPQcgimnprstz CHANLIMIT=#:120 PREFIX=(ov)@+ MAXLIST=bqeI:100 MODES=4 NETWORK=freenode KNOCK STATUSMSG=@+ CALLERID=g :are supported by this server')
      @isupport.parse('bot_nick CASEMAPPING=strict CHARSET=ascii NICKLEN=16 CHANNELLEN=50 TOPICLEN=390 ETRACE CPRIVMSG CNOTICE DEAF=D MONITOR=100 FNC TARGMAX=NAMES:1,LIST:1,KICK:1,WHOIS:1,PRIVMSG:4,NOTICE:4,ACCEPT:,MONITOR: :are supported by this server')
      @isupport.parse('bot_nick EXTBAN=$,arx WHOX CLIENTVER=3.0 SAFELIST ELIST=CTU :are supported by this server')
      @isupport['CHANTYPES'].should eq(['#'])
      @isupport['EXCEPTS'].should be_true
      @isupport['INVEX'].should be_true
      @isupport['CHANMODES'].should eq({
        'A' => %w(e I b q),
        'B' => %w(k),
        'C' => %w(f l j),
        'D' => %w(C F L M P Q c g i m n p r s t z)
        })
      @isupport['CHANLIMIT'].should eq({'#' => 120})
      @isupport['MAXLIST'].should eq({'b' => 100, 'q' => 100, 'e' => 100, 'I' => 100})
      @isupport['MODES'].should eq(4)
      @isupport['KNOCK'].should be_true
      @isupport['STATUSMSG'].should eq(['@', '+'])
      @isupport['CALLERID'].should eq('g')
      @isupport['CASEMAPPING'].should eq('strict')
      @isupport['CHARSET'].should eq('ascii')
      @isupport['NICKLEN'].should eq(16)
      @isupport['CHANNELLEN'].should eq(50)
      @isupport['TOPICLEN'].should eq(390)
      @isupport['ETRACE'].should be_true
      @isupport['CPRIVMSG'].should be_true
      @isupport['CNOTICE'].should be_true
      @isupport['DEAF'].should eq('D')
      @isupport['MONITOR'].should eq('100')
      @isupport['FNC'].should be_true
      @isupport['TARGMAX'].should eq({
        'NAMES' => 1,
        'LIST' => 1,
        'KICK' => 1,
        'WHOIS' => 1,
        'PRIVMSG' => 4,
        'NOTICE' => 4,
        'ACCEPT' => Float::INFINITY,
        'MONITOR' => Float::INFINITY
        })
      @isupport['EXTBAN'].should eq(['$', 'arx'])
      @isupport['WHOX'].should be_true
      @isupport['CLIENTVER'].should eq('3.0')
      @isupport['SAFELIST'].should be_true
      @isupport['ELIST'].should eq('CTU')
    end
  end
end
