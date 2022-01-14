require 'rails_helper'
include CommunityHelper

RSpec.describe ChatMessage, type: :model do
  it { expect(FactoryBot.build(:chat_message).save).to be true }
  it { should belong_to :messageable }
  it { should belong_to :user }
  it { should validate_presence_of :messageable_id }
  it { should validate_presence_of :messageable_type }
  it { should validate_presence_of :content }
  it { should validate_presence_of :user_id }

  describe "custom type" do
    let(:entourage) { create :entourage }
    let!(:group) { create :entourage, uuid_v2: "uuid-123" }

    def message attributes={}
      build(:chat_message, attributes.merge(messageable: entourage))
    end

    it { expect(message(message_type: nil).save).to be false }
    it { expect(message(metadata: { some: :thing }).save).to be false }
    it { expect(message(message_type: 'some_invalid_type').save).to be false }
    it { expect(message(message_type: 'text').save).to be true }
    it { expect(message(message_type: 'text', metadata: { foo: 'bar' }).save).to be false }
    it { expect(message(message_type: 'share', metadata: { type: :entourage, uuid: "uuid-123"}).save!).to be true }
  end
end
