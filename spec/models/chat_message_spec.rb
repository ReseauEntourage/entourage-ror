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

  describe "has a v2 uuid" do
    let(:chat_message) { create :chat_message }

    describe "format" do
      it { expect(chat_message.uuid_v2).not_to be_nil }
      it { expect(chat_message.uuid_v2[0]).to eq 'e' }
      it { expect(chat_message.uuid_v2.length).to eq 12 }
    end
  end

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

  describe "content" do
    let(:chat_message) { create(:chat_message, status: :active, content: "foobar") }

    before { chat_message.update_attribute(:status, status) }

    let(:status) { :active }

    context "on active" do
      let(:status) { :active }

      it { expect(chat_message.content).to eq("foobar") }
    end

    context "on updated" do
      let(:status) { :updated }

      it { expect(chat_message.content).to eq("foobar") }
    end

    context "on deleted" do
      let(:status) { :deleted }

      it { expect(chat_message.content).to eq("") }
    end

    context "on deleted and force" do
      let(:status) { :deleted }

      it { expect(chat_message.content(true)).to eq("foobar") }
    end
  end

  describe "image_url" do
    let(:chat_message) { create(:chat_message, status: status, image_url: "path/to/url") }
    let(:status) { :active }

    context "on active" do
      let(:status) { :active }

      it { expect(chat_message.image_url).to eq("path/to/url") }
    end

    context "on updated" do
      let(:status) { :updated }

      it { expect(chat_message.image_url).to eq("path/to/url") }
    end

    context "on deleted" do
      let(:status) { :deleted }

      it { expect(chat_message.image_url).to eq(nil) }
    end

    context "on deleted and force" do
      let(:status) { :deleted }

      it { expect(chat_message.image_url(true)).to eq("path/to/url") }
    end
  end

  describe "survey" do
    let(:survey) { create :survey }
    let(:chat_message) { create :chat_message, survey: survey }

    it { expect(chat_message.survey_id).to eq(survey.id) }
  end
end
