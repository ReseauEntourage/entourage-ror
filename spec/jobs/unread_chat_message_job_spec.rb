require 'rails_helper'

RSpec.describe UnreadChatMessageJob do
  describe "perform" do
    let(:user) { create(:public_user) }
    let!(:join_request) { create(:join_request, joinable: instance, status: :accepted, user: user, last_message_read: last_message_read) }
    let(:chat_message) { create(:chat_message, messageable: instance, user: instance.user) }
    let(:last_message_read) { 1.hour.ago }

    describe "on neighborhood" do
      let(:instance) { create(:neighborhood) }

      context "last_message_read < chat_message.created_at" do
        before { UnreadChatMessageJob.new.perform(chat_message.messageable_type, chat_message.messageable_id) }

        it { expect(join_request.reload.unread_messages_count).to eq(1) }
      end

      context "last_message_read > chat_message.created_at" do
        let(:last_message_read) { 1.hour.from_now }

        before { UnreadChatMessageJob.new.perform(chat_message.messageable_type, chat_message.messageable_id) }

        it { expect(join_request.reload.unread_messages_count).to eq(0) }
      end
    end

    describe "on outing" do
      let(:instance) { create(:outing) }

      context "last_message_read < chat_message.created_at" do
        before { UnreadChatMessageJob.new.perform(chat_message.messageable_type, chat_message.messageable_id) }

        it { expect(join_request.reload.unread_messages_count).to eq(1) }
      end

      context "last_message_read > chat_message.created_at" do
        let(:last_message_read) { 1.hour.from_now }

        before { UnreadChatMessageJob.new.perform(chat_message.messageable_type, chat_message.messageable_id) }

        it { expect(join_request.reload.unread_messages_count).to eq(0) }
      end
    end

    describe "on action" do
      let(:instance) { create(:entourage) }

      before { UnreadChatMessageJob.new.perform(chat_message.messageable_type, chat_message.messageable_id) }

      it { expect(join_request.reload.unread_messages_count).to be_nil }
    end
  end
end
