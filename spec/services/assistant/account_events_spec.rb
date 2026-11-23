require 'rails_helper'

describe Assistant::AccountEvents do
  it 'is enabled only with the URL and the service key' do
    allow(ENV).to receive(:[]).and_call_original
    allow(ENV).to receive(:[]).with('ASSISTANT_API_URL').and_return('https://assistant.example.org')
    allow(ENV).to receive(:[]).with('ASSISTANT_SERVICE_KEY').and_return(nil)
    expect(described_class).not_to be_enabled

    allow(ENV).to receive(:[]).with('ASSISTANT_SERVICE_KEY').and_return('key')
    expect(described_class).to be_enabled

    allow(ENV).to receive(:[]).with('ASSISTANT_API_URL').and_return('')
    expect(described_class).not_to be_enabled
  end

  it 'sends the events to the product-events route of the assistant, whatever the trailing slash of the base URL' do
    allow(ENV).to receive(:[]).and_call_original
    ['https://assistant.example.org', 'https://assistant.example.org/'].each do |base|
      allow(ENV).to receive(:[]).with('ASSISTANT_API_URL').and_return(base)

      expect(described_class.events_url).to eq('https://assistant.example.org/api/v1/product-events')
    end
  end

  it 'tells an anonymized account from a deleted one' do
    expect(described_class.event_for(build(:public_user, validation_status: 'anonymized'))).to eq('account.anonymized')
    expect(described_class.event_for(build(:public_user, validation_status: 'deleted'))).to eq('account.deleted')
    expect(described_class.event_for(build(:public_user, validation_status: 'blocked'))).to eq('account.deleted')
  end
end
