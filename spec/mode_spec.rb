require 'spec_helper'

describe 'MODE' do
  before(:each) do
    @thaum = Ponder::Thaum.new do |t|
      t.nick    = 'Ponder'
      t.verbose = false
    end

    # The Thaum is connected.
    @thaum.parse(':server 376 Ponder :End of /MOTD command.')
  end

  it 'gives back the channel creation epoch time and the channel sets it' do
    Ponder::Recipient.any_instance.stub(:raw)
    @thaum.parse(':Ponder!foo@bar JOIN #mended_drum')
    @thaum.parse(':server 329 Ponder #mended_drum 1360062556')

    channel = @thaum.channel_list.find('#mended_drum')
    expect(channel.created_at).to be_kind_of(Time)
    expect(channel.created_at).to eq(Time.at(1360062556))
  end

  it 'gives back channel modes and the channel sets them' do
    Ponder::Recipient.any_instance.stub(:raw)
    @thaum.parse(':Ponder!foo@bar JOIN #mended_drum')
    @thaum.parse ':server 324 Ponder #mended_drum +ns'

    channel = @thaum.channel_list.find('#mended_drum')
    expect(channel.modes['n']).to be_true
    expect(channel.modes['s']).to be_true
  end

  it 'gives back channel modes and the channel sets them' do
    Ponder::Recipient.any_instance.stub(:raw)
    @thaum.parse(':Ponder!foo@bar JOIN #mended_drum')
    @thaum.parse ':server 324 Ponder #mended_drum +nsk channel_key'

    channel = @thaum.channel_list.find('#mended_drum')
    expect(channel.modes['k']).to eq('channel_key')
  end
end
