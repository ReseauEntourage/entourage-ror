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

  describe '.interpolate' do
    let(:user) { create(:public_user,
      first_name: 'John',
      email: 'john.doe@example.com',
      phone: '+33612345678',
      uuid: '123e4567-e89b-12d3-a456-426614174000',
      interest_list: 'jeux, cuisine',
      involvement_list: 'outings, resources',
      availability: {
        "1" => ["09:00-12:00", "14:00-18:00"],
        "2" => ["10:00-12:00"]
      },
      address: address,
      addresses: [address]
    )}

    let(:other_user) { create(:public_user) }
    let(:author) { create(:public_user, first_name: 'Alice') }

    let(:neighborhood) { create(:neighborhood, name: "Groupe de Paris") }
    let(:address) { create :address, city: "Paris" }

    before do
      allow(user).to receive(:default_neighborhood).and_return(neighborhood)
      allow(UserPresenter).to receive(:format_first_name).with('John').and_return('John')
    end

    it 'replaces placeholders in the message' do
      message = <<~TEXT
        Hello {{ first_name }},
        Your email is {{ email }}, and your phone number is {{ phone }}.
        You live in {{ city }} and your ID is {{ uuid }}.
        Default neighborhood: {{ default_neighborhood }}.
        Your interests: {{ interests }}.
        Your involvements: {{ involvements }}.
        Availability: {{ availability }}.
        Interlocutor: {{ interlocutor }}.
      TEXT

      expected_message = <<~TEXT
        Hello John,
        Your email is john.doe@example.com, and your phone number is +33612345678.
        You live in Paris and your ID is 123e4567-e89b-12d3-a456-426614174000.
        Default neighborhood: Groupe de Paris.
        Your interests: Cuisine, Jeux.
        Your involvements: Apprendre avec des contenus pédagogiques, Participer à des événements de convivialité.
        Availability: lundi : 09:00-12:00, 14:00-18:00
        mardi : 10:00-12:00.
        Interlocutor: Alice.
      TEXT

      result = ChatMessage.interpolate(message: message, user: user, author: author)
      expect(result.strip).to eq(expected_message.strip)
    end

    it 'replaces placeholders in the message when user has little information' do
      message = <<~TEXT
        Hello {{ first_name }},
        Your email is {{ email }}, and your phone number is {{ phone }}.
        You live in {{ city }} and your ID is {{ uuid }}.
        Default neighborhood: {{ default_neighborhood }}.
        Your interests: {{ interests }}.
        Your involvements: {{ involvements }}.
        Availability: {{ availability }}.
        Interlocutor: {{ interlocutor }}.
      TEXT

      expected_message = <<~TEXT
        Hello John,
        Your email is #{other_user.email}, and your phone number is #{other_user.phone}.
        You live in  and your ID is #{other_user.uuid}.
        Default neighborhood: .
        Your interests: .
        Your involvements: .
        Availability: .
        Interlocutor: Alice.
      TEXT

      result = ChatMessage.interpolate(message: message, user: other_user, author: author)
      expect(result.strip).to eq(expected_message.strip)
    end

    it 'handles missing placeholders gracefully when author is nil' do
      message = "Hello {{ first_name }}, your interlocutor is {{ interlocutor }}."
      expected_message = "Hello John, your interlocutor is ."

      result = ChatMessage.interpolate(message: message, user: user, author: nil)
      expect(result).to eq(expected_message)
    end

    it 'handles missing placeholders in the message' do
      message = "This message has no placeholders."
      expected_message = "This message has no placeholders."

      result = ChatMessage.interpolate(message: message, user: user)
      expect(result).to eq(expected_message)
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
