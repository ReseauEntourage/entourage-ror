require 'rails_helper'

describe ChatServices::PrivateConversation do
  let(:user) { create(:user, goal: :offer_help) }
  let(:interlocutor) { create(:user, admin: true, roles: [:moderator]) }
  let(:conversation) { create(:conversation) }

  let(:chat_message) { build(:chat_message, messageable: conversation, user: user, content: "content", created_at: Time.zone.now) }

  let!(:join_request_user) { create(:join_request, joinable: conversation, status: :accepted, user: user) }
  let!(:join_request_interlocutor) { create(:join_request, joinable: conversation, status: :accepted, user: interlocutor) }

  describe "notify_moderator_not_available" do
    subject { chat_message.notify_moderator_not_available }

    it { expect { subject }.to change { ChatMessage.count }.by(1) }

    context "working_hours_sent_at changed" do
      before { subject }

      it { expect(chat_message.messageable.working_hours_sent_at).to be_a(ActiveSupport::TimeWithZone) }
    end
  end

  describe "notify_moderator_not_available?" do
    before { Timecop.freeze(Time.zone.now.change(hour: 0)) }

    subject { chat_message.notify_moderator_not_available? }

    context "notify" do

      it { expect(subject).to eq(true) }
    end

    context "user is ask_for_help" do
      let(:user) { create(:user, goal: :ask_for_help) }

      it { expect(subject).to eq(false) }
    end

    context "user is a moderator" do
      let(:user) { create(:user, goal: :offer_help, admin: true, roles: [:moderator]) }

      it { expect(subject).to eq(false) }
    end

    context "messageable is not a conversation" do
      let(:conversation) { create(:outing) }

      it { expect(subject).to eq(false) }
    end

    context "interlocutor is not a moderator" do
      let(:interlocutor) { create(:user, admin: true) }

      it { expect(subject).to eq(false) }
    end

    context "during working hours" do
      before { Timecop.freeze(Time.zone.now.change(hour: 12)) }

      it { expect(subject).to eq(false) }
    end

    context "notify already sent" do
      before { conversation.update_attribute(:working_hours_sent_at, Time.zone.now) }

      it { expect(subject).to eq(false) }
    end

    context "notify already sent but is old" do
      before { conversation.update_attribute(:working_hours_sent_at, 1.week.ago) }

      it { expect(subject).to eq(true) }
    end
  end
end
