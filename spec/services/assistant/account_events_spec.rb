require 'rails_helper'

describe Assistant::AccountEvents do
  it 'is enabled only with the URL and the service key' do
    allow(ENV).to receive(:[]).and_call_original
    allow(ENV).to receive(:[]).with('ASSISTANT_API_URL').and_return('https://assistant.example.org/events')
    allow(ENV).to receive(:[]).with('ASSISTANT_SERVICE_KEY').and_return(nil)
    expect(described_class).not_to be_enabled

    allow(ENV).to receive(:[]).with('ASSISTANT_SERVICE_KEY').and_return('key')
    expect(described_class).to be_enabled

    allow(ENV).to receive(:[]).with('ASSISTANT_API_URL').and_return('')
    expect(described_class).not_to be_enabled
  end

  it 'tells an anonymized account from a deleted one' do
    expect(described_class.event_for(build(:public_user, validation_status: 'anonymized'))).to eq('account.anonymized')
    expect(described_class.event_for(build(:public_user, validation_status: 'deleted'))).to eq('account.deleted')
    expect(described_class.event_for(build(:public_user, validation_status: 'blocked'))).to eq('account.deleted')
  end
end
