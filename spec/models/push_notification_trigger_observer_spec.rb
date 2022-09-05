require 'rails_helper'

RSpec.describe PushNotificationTriggerObserver, type: :model do
  include ActiveJob::TestHelper

  let(:user) { create :public_user }
  let(:participant) { create :public_user }

  # after_create
  describe "after_create" do
    describe "on_create is received" do
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
        let(:neighborhood) { create :neighborhood }

        context "text chat_message" do
          it {
            expect_any_instance_of(PushNotificationTriggerObserver).to receive(:chat_message_on_create)
            create :chat_message, user: user, message_type: :text
          }
        end

        context "broadcast chat_message" do
          let!(:broadcast) { FactoryBot.create(:conversation_message_broadcast) }

          it {
            expect_any_instance_of(PushNotificationTriggerObserver).to receive(:chat_message_on_create)
            create :chat_message, user: user, message_type: :broadcast, metadata: { conversation_message_broadcast_id: broadcast.id }
          }
        end

        context "status chat_message" do
          it {
            expect_any_instance_of(PushNotificationTriggerObserver).not_to receive(:post_on_create)
            expect_any_instance_of(PushNotificationTriggerObserver).not_to receive(:comment_on_create)
            create :chat_message, user: user, message_type: :status_update, metadata: { status: :foo, outcome_success: true }
          }
        end

        context "private_chat_message" do
          it {
            expect_any_instance_of(PushNotificationTriggerObserver).to receive(:private_chat_message_on_create)
            expect_any_instance_of(PushNotificationTriggerObserver).not_to receive(:post_on_create)
            expect_any_instance_of(PushNotificationTriggerObserver).not_to receive(:comment_on_create)
            create :chat_message, user: user, message_type: :text
          }
        end

        context "post chat_message in neighborhood" do
          it {
            expect_any_instance_of(PushNotificationTriggerObserver).not_to receive(:private_chat_message_on_create)
            expect_any_instance_of(PushNotificationTriggerObserver).to receive(:post_on_create)
            expect_any_instance_of(PushNotificationTriggerObserver).not_to receive(:comment_on_create)
            create :chat_message, user: user, message_type: :text, messageable: neighborhood
          }
        end

        context "comment" do
          let!(:chat_message) { create :chat_message, messageable: neighborhood, user: user, message_type: :text }

          it {
            expect_any_instance_of(PushNotificationTriggerObserver).not_to receive(:post_on_create)
            expect_any_instance_of(PushNotificationTriggerObserver).to receive(:comment_on_create)
            create :chat_message, user: user, message_type: :text, parent: chat_message
          }
        end
      end

      describe "join_request" do
        it {
          expect_any_instance_of(PushNotificationTriggerObserver).to receive(:join_request_on_create)
          create :join_request, user: user, status: :accepted
        }
      end
    end

    describe "notify is received" do
      describe "outing" do
        let(:neighborhood) { create(:neighborhood) }

        it {
          expect_any_instance_of(PushNotificationTriggerObserver).not_to receive(:notify)
          create :outing, user: user
        }

        it {
          expect_any_instance_of(PushNotificationTriggerObserver).to receive(:notify)
          create :outing, user: user, neighborhoods: [neighborhood]
        }
      end

      describe "join_request" do
        it {
          expect_any_instance_of(PushNotificationTriggerObserver).to receive(:notify)
          create :join_request, user: user, status: :accepted
        }

        it {
          expect_any_instance_of(PushNotificationTriggerObserver).not_to receive(:notify)
          create :join_request, user: user, status: :pending
        }
      end
    end
  end

  # after_update
  describe "after_update" do
    describe "on_update is received" do
      describe "outing" do
        let!(:outing) { create :outing, user: user, status: :open }

        it {
          expect_any_instance_of(PushNotificationTriggerObserver).to receive(:outing_on_update)
          outing.update_attribute(:title, "foo")
        }
      end
    end

    describe "notify is received" do
      describe "outing with participant" do
        let!(:outing) { create :outing, user: user, status: :open }
        let!(:join_request) { create :join_request, user: participant, joinable: outing, status: :accepted }

        it {
          expect_any_instance_of(PushNotificationTriggerObserver).to receive(:notify)
          outing.update_attribute(:title, "foo")
        }
      end

      describe "outing without participant" do
        let!(:outing) { create :outing, user: user, status: :open }

        it {
          expect_any_instance_of(PushNotificationTriggerObserver).not_to receive(:notify)
          outing.update_attribute(:title, "foo")
        }
      end
    end
  end

  # after_cancel
  describe "on_cancel" do
    describe "on_cancel is received" do
      describe "outing" do
        let!(:outing) { create :outing, user: user, status: :open }

        it {
          expect_any_instance_of(PushNotificationTriggerObserver).to receive(:outing_on_cancel)
          outing.update_attribute(:status, :cancelled)
        }
      end
    end

    describe "notify is received" do
      describe "outing with participant" do
        let!(:outing) { create :outing, user: user, status: :open }
        let!(:join_request) { create :join_request, user: participant, joinable: outing, status: :accepted }

        it {
          expect_any_instance_of(PushNotificationTriggerObserver).to receive(:notify)
          outing.update_attribute(:status, :cancelled)
        }
      end

      describe "outing without participant" do
        let!(:outing) { create :outing, user: user, status: :open }

        it {
          expect_any_instance_of(PushNotificationTriggerObserver).not_to receive(:notify)
          outing.update_attribute(:status, :cancelled)
        }
      end
    end
  end
end
