require 'rails_helper'
include CommunityHelper

RSpec.describe ChatMessage, type: :model do
  it { expect(FactoryGirl.build(:chat_message).save).to be true }
  it { should belong_to :messageable }
  it { should belong_to :user }
  it { should validate_presence_of :messageable_id }
  it { should validate_presence_of :messageable_type }
  it { should validate_presence_of :content }
  it { should validate_presence_of :user_id }

  describe "custom type" do
    with_community :pfp
    let(:circle) { create :private_circle, title: "Les amis de Henriette" }

    def message attributes={}
      build(
        :chat_message,
        attributes.merge(messageable: circle)
      )
    end

    it { expect(message(message_type: nil).save).to be false }
    it { expect(message(metadata: { some: :thing }).save).to be false }
    it { expect(message(message_type: 'some_invalid_type').save).to be false }
    it { expect(message(message_type: 'visit').save).to be false }
    it { expect(message(message_type: 'visit', metadata: { visited_at: 'not_a_date' }).save).to be false }
    it { expect(message(message_type: 'visit', metadata: { visited_at: '2018-05-31T00:00:00Z' }).save).to be true }
    it { expect(message(message_type: 'visit', metadata: { visited_at: '2018-06-06T12:22:25.669+0300' }).save).to be true }
  end

  describe "visit_content" do
    with_community :pfp
    let(:author) { create :public_user, roles: [role] }
    let(:circle) { create :private_circle, title: "Les amis de Henriette" }

    def message date
      create(
        :chat_message,
        messageable: circle,
        user: author,
        message_type: 'visit',
        metadata: { visited_at: date.iso8601 }
      ).content
    end

    context "as a visitor" do
      let(:role) { :visitor }
      it { expect(message(Time.zone.now)).to eq "J'ai voisiné Henriette aujourd'hui" }
      it { expect(message(1.day.ago)).to eq "J'ai voisiné Henriette hier" }
      it { expect(message(2.years.ago.change(month: 2, day: 5))).to eq "J'ai voisiné Henriette le 5 février" }
      it { expect(message(2.years.from_now.change(month: 9, day: 27))).to eq "Je voisinerai Henriette le 27 septembre" }
    end

    context "as a visited" do
      let(:role) { :visited }
      it { expect(message(Time.zone.now)).to eq "J'ai été voisiné(e) aujourd'hui" }
      it { expect(message(1.day.ago)).to eq "J'ai été voisiné(e) hier" }
      it { expect(message(2.years.ago.change(month: 2, day: 5))).to eq "J'ai été voisiné(e) le 5 février" }
      it { expect(message(2.years.from_now.change(month: 9, day: 27))).to eq "Je serai voisiné(e) le 27 septembre" }
    end
  end
end
