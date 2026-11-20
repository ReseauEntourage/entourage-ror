require 'rails_helper'

describe AssistantAction do
  let(:user) { create(:public_user) }
  let(:attributes) do
    { user: user, idempotency_key: SecureRandom.uuid, action_type: 'outing.join', request_digest: 'abc' }
  end

  it 'is valid with a user, a key, a type and a digest, and starts as processing' do
    action = described_class.create!(attributes)

    expect(action).to be_processing
    expect(action.result).to eq({})
  end

  [:user, :idempotency_key, :action_type, :request_digest].each do |attribute|
    it "requires #{attribute}" do
      expect(described_class.new(attributes.merge(attribute => nil))).not_to be_valid
    end
  end

  it 'only accepts the known statuses' do
    expect(described_class.new(attributes.merge(status: 'done'))).not_to be_valid
    expect(described_class.new(attributes.merge(status: 'failed'))).to be_valid
  end

  it 'refuses the same key twice for the same user, in the model and in the database' do
    described_class.create!(attributes)
    twin = described_class.new(attributes.merge(request_digest: 'other'))

    expect(twin).not_to be_valid
    expect { twin.save!(validate: false) }.to raise_error(ActiveRecord::RecordNotUnique)
  end

  it 'accepts the same key for two users' do
    described_class.create!(attributes)

    expect(described_class.new(attributes.merge(user: create(:public_user)))).to be_valid
  end

  it 'keeps the object created by the action as its subject' do
    outing = create(:outing)
    action = described_class.create!(attributes.merge(subject: outing))

    expect(action.reload.subject).to eq(outing)
    expect(described_class.where(subject_type: 'Entourage', subject_id: outing.id)).to include(action)
  end
end
