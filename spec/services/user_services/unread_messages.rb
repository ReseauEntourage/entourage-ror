require 'rails_helper'

describe UserServices::UnreadMessages do
  describe 'unread_conversations' do
    let(:subject) { UserServices::UnreadMessages.new(user: user).unread_conversations }

    let(:user) { create(:public_user) }
    let!(:join_request) { create(:join_request, joinable: joinable, user: user, status: :accepted, last_message_read: last_message_read) }
    let!(:chat_message) { FactoryBot.create(:chat_message, created_at: 1.minute.ago, messageable: joinable) }

    context "with unread on a conversation, old last_message_read" do
      let(:joinable) { create :conversation, user: user }
      let(:last_message_read) { 1.day.ago }

      it { expect(subject).to match_array([joinable.id])}
    end

    context "with unread on a conversation, no last_message_read" do
      let(:joinable) { create :conversation, user: user }
      let(:last_message_read) { nil }

      it { expect(subject).to match_array([joinable.id])}
    end

    context "with no unread on a conversation" do
      let(:joinable) { create :conversation, user: user }
      let(:last_message_read) { Time.now }

      it { expect(subject).to match_array([])}
    end

    context "with unread on a outing is not relevant" do
      let(:joinable) { create :outing, user: user }
      let(:last_message_read) { 1.day.ago }

      it { expect(subject).to match_array([])}
    end

    context "with unread on a entourage is not relevant" do
      let(:joinable) { create :entourage, user: user }
      let(:last_message_read) { 1.day.ago }

      it { expect(subject).to match_array([])}
    end
  end
end
