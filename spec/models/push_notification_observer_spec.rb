require 'rails_helper'

RSpec.describe PushNotificationTriggerObserver, type: :model do
  include ActiveJob::TestHelper

  # after_create
  describe "after_create" do
    let(:user) { create :public_user }

    describe "entourage" do
      it {
        expect_any_instance_of(PushNotificationTriggerObserver).not_to receive(:outing_on_create)
        create :entourage, user: user
      }
    end

    describe "outing" do
      it {
        expect_any_instance_of(PushNotificationTriggerObserver).to receive(:outing_on_create)
        create :outing, user: user
      }
    end

    describe "chat_message" do
      let!(:chat_message) { create :chat_message, user: user, message_type: :text }

      it {
        expect_any_instance_of(PushNotificationTriggerObserver).to receive(:chat_message_on_create)
        create :chat_message, user: user, message_type: :text
      }

      let!(:broadcast) { FactoryBot.create(:conversation_message_broadcast) }

      it {
        expect_any_instance_of(PushNotificationTriggerObserver).to receive(:chat_message_on_create)
        create :chat_message, user: user, message_type: :broadcast, metadata: { conversation_message_broadcast_id: broadcast.id }
      }

      it {
        expect_any_instance_of(PushNotificationTriggerObserver).not_to receive(:post_on_create)
        expect_any_instance_of(PushNotificationTriggerObserver).not_to receive(:comment_on_create)
        create :chat_message, user: user, message_type: :status_update, metadata: { status: :foo, outcome_success: true }
      }

      it {
        expect_any_instance_of(PushNotificationTriggerObserver).to receive(:post_on_create)
        expect_any_instance_of(PushNotificationTriggerObserver).not_to receive(:comment_on_create)
        create :chat_message, user: user, message_type: :text
      }

      it {
        expect_any_instance_of(PushNotificationTriggerObserver).not_to receive(:post_on_create)
        expect_any_instance_of(PushNotificationTriggerObserver).to receive(:comment_on_create)
        create :chat_message, user: user, message_type: :text, parent: chat_message
      }
    end
  end
end
