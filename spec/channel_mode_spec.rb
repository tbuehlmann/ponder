require 'spec_helper'

describe "Ponder::IRC::Events::ChannelMode" do
  before(:each) do
    @thaum = Ponder::Thaum.new do |config|
      config.nick = 'Ponder'
      config.verbose = false
    end

    Ponder::Channel.any_instance.stub(:get_mode)

    # Connected to a server and joining a channel.
    @thaum.parse ':server 376 Ponder :End of /MOTD command.'
    @thaum.parse ':Ponder!foo@bar JOIN #mended_drum'
    @thaum.parse ':TheLibrarian!foo@bar JOIN #mended_drum'
    @thaum.parse ':Ridcully!foo@bar JOIN #mended_drum'
  end

  it 'is created correctly' do
    channel = @thaum.channel_list.find('#mended_drum')

    @thaum.on :channel_mode do |event_data|
      expect(event_data[:channel_modes]).to have(1).element
      channel_mode = event_data[:channel_modes].first
      expect(channel_mode.channel).to eql(channel)
      expect(channel_mode.direction).to eql(:'+')
      expect(channel_mode.mode).to eql('o')
      expect(channel_mode.param).to eql('Ponder')
      @called = true
    end

    @thaum.parse ':TheLibrarian!foo@bar MODE #mended_drum +o Ponder'
    expect(@called).to be_true
  end

  it 'is created correctly with many mode changes' do
    channel = @thaum.channel_list.find('#mended_drum')

    @thaum.on :channel_mode do |event_data|
      expect(event_data[:channel_modes]).to have(2).elements
      expect(event_data[:channel_modes][0].channel).to eql(channel)
      expect(event_data[:channel_modes][1].channel).to eql(channel)
      expect(event_data[:channel_modes][0].direction).to eql(:'+')
      expect(event_data[:channel_modes][1].direction).to eql(:'+')
      expect(event_data[:channel_modes][0].mode).to eql('o')
      expect(event_data[:channel_modes][1].mode).to eql('v')
      expect(event_data[:channel_modes][0].param).to eql('Ponder')
      expect(event_data[:channel_modes][1].param).to eql('Ridcully')
      @called = true
    end

    @thaum.parse ':TheLibrarian!foo@bar MODE #mended_drum +ov Ponder Ridcully'
    expect(@called).to be_true
  end

  it 'is created 2 times, even if there are 7 modes but just 2 params' do
    channel = @thaum.channel_list.find('#mended_drum')

    @thaum.on :channel_mode do |event_data|
      expect(event_data[:channel_modes]).to have(2).elements
      @called = true
    end

    @thaum.parse ':TheLibrarian!foo@bar MODE #mended_drum +ovvvvvv Ponder Ridcully'
    expect(@called).to be_true
  end

  context 'category PREFIX (B)' do
    it 'sets a single channel mode (+o) correctly' do
      channel = @thaum.channel_list.find('#mended_drum')

      @thaum.parse ':TheLibrarian!foo@bar MODE #mended_drum +o Ponder'
      expect(channel.modes_of('Ponder')).to eql(['o'])
    end

    it 'removes a single channel mode (-o) correctly' do
      channel = @thaum.channel_list.find('#mended_drum')

      @thaum.parse ':TheLibrarian!foo@bar MODE #mended_drum +o Ponder'
      expect(channel.modes_of('Ponder')).to eql(['o'])

      @thaum.parse ':TheLibrarian!foo@bar MODE #mended_drum -o Ponder'
      expect(channel.modes_of('Ponder')).to be_empty
    end
  end

  context 'category A' do
    it 'sets a single channel mode correctly' do
      channel = @thaum.channel_list.find('#mended_drum')
      @thaum.parse ':TheLibrarian!foo@bar MODE #mended_drum +b Ponder!foo@bar'
      expect(channel.lists['b']).to eql(['Ponder!foo@bar'])
    end

    it 'removes a single channel mode correctly' do
      channel = @thaum.channel_list.find('#mended_drum')
      @thaum.parse ':TheLibrarian!foo@bar MODE #mended_drum +b Ponder!foo@bar'
      expect(channel.lists['b']).to eql(['Ponder!foo@bar'])

      @thaum.parse ':TheLibrarian!foo@bar MODE #mended_drum -b Ponder!foo@bar'
      expect(channel.lists['b']).to be_empty
    end
  end

  context 'category B' do
    it 'sets a single channel mode correctly' do
      channel = @thaum.channel_list.find('#mended_drum')
      @thaum.parse ':TheLibrarian!foo@bar MODE #mended_drum +k channel_key'
      expect(channel.modes['k']).to eql('channel_key')
    end

    it 'removes a single channel mode correctly' do
      channel = @thaum.channel_list.find('#mended_drum')
      @thaum.parse ':TheLibrarian!foo@bar MODE #mended_drum +k channel_key'
      expect(channel.modes['k']).to eql('channel_key')

      @thaum.parse ':TheLibrarian!foo@bar MODE #mended_drum -k channel_key'
      expect(channel.modes.keys).to be_empty
    end
  end

  context 'category C' do
    it 'sets a single channel mode correctly' do
      channel = @thaum.channel_list.find('#mended_drum')
      @thaum.parse ':TheLibrarian!foo@bar MODE #mended_drum +l 5'
      expect(channel.modes['l']).to eql('5')
    end

    it 'removes a single channel mode correctly' do
      channel = @thaum.channel_list.find('#mended_drum')
      @thaum.parse ':TheLibrarian!foo@bar MODE #mended_drum +l 5'
      expect(channel.modes['l']).to eql('5')

      @thaum.parse ':TheLibrarian!foo@bar MODE #mended_drum -l'
      expect(channel.modes['l']).to be_nil
    end
  end

  context 'category D' do
    it 'sets a single channel mode correctly' do
      channel = @thaum.channel_list.find('#mended_drum')
      @thaum.parse ':TheLibrarian!foo@bar MODE #mended_drum +p'
      expect(channel.modes['p']).to be_true
    end

    it 'removes a single channel mode correctly' do
      channel = @thaum.channel_list.find('#mended_drum')
      @thaum.parse ':TheLibrarian!foo@bar MODE #mended_drum +p'
      expect(channel.modes['p']).to be_true

      @thaum.parse ':TheLibrarian!foo@bar MODE #mended_drum -p'
      expect(channel.modes['p']).to be_nil
    end
  end
end
