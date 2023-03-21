require 'rails_helper'

RSpec.describe PushNotificationTriggerObserver, type: :model do
  include ActiveJob::TestHelper

  let(:paris) { { latitude: 48.87, longitude: 2.33 } }
  let(:nantes) { { latitude: 47.22, longitude: -1.55 } }
  let(:address_paris) { FactoryBot.create(:address, latitude: paris[:latitude], longitude: paris[:longitude]) }

  let(:user) { create :public_user, first_name: "John" }
  let(:user_paris) { create :public_user, first_name: "Doe", addresses: [address_paris] }
  let(:participant) { create :public_user, first_name: "Jane" }

  # after_create
  describe "after_create" do
    describe "on_create is received" do
      describe "outing attached to neighborhoods" do
        let(:subject) { create :outing, user: user, neighborhoods: [create(:neighborhood)] }

        after { subject }

        it { expect_any_instance_of(PushNotificationService).to receive(:send_notification) }
        it { expect_any_instance_of(InappNotificationServices::Builder).to receive(:instanciate) }

        it { expect_any_instance_of(PushNotificationTrigger).to receive(:neighborhoods_entourage_on_create) }
        it { expect_any_instance_of(PushNotificationTrigger).to receive(:entourage_on_create) }
        it { expect_any_instance_of(PushNotificationTrigger).to receive(:entourage_on_create_for_followers) }
        it { expect_any_instance_of(PushNotificationTrigger).not_to receive(:entourage_on_create_for_neighbors) }
      end

      describe "outing not attached to neighborhoods" do
        let(:subject) { create :outing, user: user }

        after { subject }

        it { expect_any_instance_of(PushNotificationService).not_to receive(:send_notification) }
        it { expect_any_instance_of(InappNotificationServices::Builder).not_to receive(:instanciate) }

        it { expect_any_instance_of(PushNotificationTrigger).not_to receive(:neighborhoods_entourage_on_create) }
        it { expect_any_instance_of(PushNotificationTrigger).to receive(:entourage_on_create) }
        it { expect_any_instance_of(PushNotificationTrigger).to receive(:entourage_on_create_for_followers) }
        it { expect_any_instance_of(PushNotificationTrigger).not_to receive(:entourage_on_create_for_neighbors) }
      end

      describe "contribution" do
        let(:subject) { create :contribution, user: user }

        after { subject }

        it { expect_any_instance_of(PushNotificationTrigger).not_to receive(:entourage_on_create) }
        it { expect_any_instance_of(PushNotificationTrigger).to receive(:contribution_on_create) }
        it { expect_any_instance_of(PushNotificationTrigger).to receive(:entourage_on_create_for_followers) }
        it { expect_any_instance_of(PushNotificationTrigger).to receive(:entourage_on_create_for_neighbors) }
      end

      describe "contribution with neighbor" do
        let(:subject) { create :contribution, user: user, latitude: paris[:latitude], longitude: paris[:longitude] }
        let!(:notification_permission) { create :notification_permission, user: user_paris }

        before { user_paris }

        after { subject }

        it { expect_any_instance_of(PushNotificationTrigger).to receive(:entourage_on_create_for_neighbors) }
        it { expect_any_instance_of(PushNotificationTrigger).to receive(:notify) }
        it { expect_any_instance_of(InappNotificationServices::Builder).to receive(:instanciate) }
        it { expect_any_instance_of(InappNotification).to receive(:save) }
      end

      describe "contribution with neighbor for away" do
        let(:subject) { create :contribution, user: user, latitude: nantes[:latitude], longitude: nantes[:longitude] }

        after { subject }

        it { expect_any_instance_of(PushNotificationTrigger).to receive(:entourage_on_create_for_neighbors) }
        it { expect_any_instance_of(PushNotificationTrigger).not_to receive(:notify) }
      end

      describe "contribution without neighbor" do
        let(:subject) { create :contribution, user: user, latitude: paris[:latitude], longitude: paris[:longitude] }

        after { subject }

        it { expect_any_instance_of(PushNotificationTrigger).to receive(:entourage_on_create_for_neighbors) }
        it { expect_any_instance_of(PushNotificationTrigger).not_to receive(:notify) }
      end

      describe "chat_message" do
        let(:neighborhood) { create :neighborhood }

        context "text chat_message" do
          it {
            expect_any_instance_of(PushNotificationTrigger).to receive(:chat_message_on_create)
            create :chat_message, user: user, message_type: :text
          }
        end

        context "broadcast chat_message" do
          let!(:broadcast) { FactoryBot.create(:conversation_message_broadcast) }

          it {
            expect_any_instance_of(PushNotificationTrigger).to receive(:chat_message_on_create)
            create :chat_message, user: user, message_type: :broadcast, metadata: { conversation_message_broadcast_id: broadcast.id }
          }
        end

        context "status chat_message" do
          it {
            expect_any_instance_of(PushNotificationTrigger).not_to receive(:post_on_create)
            expect_any_instance_of(PushNotificationTrigger).not_to receive(:comment_on_create)
            create :chat_message, user: user, message_type: :status_update, metadata: { status: :foo, outcome_success: true }
          }
        end

        context "private_chat_message" do
          it {
            expect_any_instance_of(PushNotificationTrigger).to receive(:private_chat_message_on_create)
            expect_any_instance_of(PushNotificationTrigger).not_to receive(:post_on_create)
            expect_any_instance_of(PushNotificationTrigger).not_to receive(:comment_on_create)
            create :chat_message, user: user, message_type: :text
          }
        end

        context "post chat_message in neighborhood" do
          it {
            expect_any_instance_of(PushNotificationTrigger).not_to receive(:private_chat_message_on_create)
            expect_any_instance_of(PushNotificationTrigger).to receive(:post_on_create)
            expect_any_instance_of(PushNotificationTrigger).not_to receive(:comment_on_create)
            create :chat_message, user: user, message_type: :text, messageable: neighborhood
          }
        end

        context "comment with no notification" do
          let(:chat_message) { create :chat_message, messageable: neighborhood, user: user, message_type: :text }
          let!(:comment) { create :chat_message, messageable: neighborhood, parent: chat_message, user: user, message_type: :text }

          context "sender is publisher" do
            it {
              expect_any_instance_of(PushNotificationTrigger).not_to receive(:notify)
              create :chat_message, messageable: neighborhood, user: user, message_type: :text, parent: chat_message
            }
          end
        end

        context "comment with notification" do
          let(:john) { create :public_user, first_name: "John", last_name: "Doe" }
          let(:jane) { create :public_user, first_name: "Jane", last_name: "Doe" }

          let(:chat_message) { create :chat_message, messageable: neighborhood, user: user, message_type: :text }
          let!(:comment_1) { create :chat_message, messageable: neighborhood, parent: chat_message, user: user, message_type: :text }
          let!(:comment_2) { create :chat_message, messageable: neighborhood, parent: chat_message, user: john, message_type: :text }
          let!(:comment_3) { create :chat_message, messageable: neighborhood, parent: chat_message, user: john, message_type: :text }
          let!(:comment_4) { create :chat_message, messageable: neighborhood, parent: chat_message, user: jane, message_type: :text }

          it {
            expect_any_instance_of(PushNotificationTrigger).not_to receive(:post_on_create)
            expect_any_instance_of(PushNotificationTrigger).to receive(:comment_on_create)
            create :chat_message, messageable: neighborhood, user: user, message_type: :text, parent: chat_message
          }

          context "sender is publisher" do
            it {
              expect_any_instance_of(PushNotificationTrigger).to receive(:notify).with(
                sender_id: user.id,
                referent: neighborhood,
                instance: chat_message,
                users: [john, jane],
                params: {
                  object: neighborhood.title,
                  content: "John D. vient de commenter la publication \"#{chat_message.content}\""
                }
              )
              create :chat_message, messageable: neighborhood, user: user, message_type: :text, parent: chat_message
            }
          end

          context "sender is commentator" do
            it {
              expect_any_instance_of(PushNotificationTrigger).to receive(:notify).with(
                sender_id: john.id,
                referent: neighborhood,
                instance: chat_message,
                users: [user, jane],
                params: {
                  object: neighborhood.title,
                  content: "John D. vient de commenter la publication \"#{chat_message.content}\""
                }
              )
              create :chat_message, messageable: neighborhood, user: john, message_type: :text, parent: chat_message
            }
          end
        end
      end

      describe "join_request" do
        it {
          expect_any_instance_of(PushNotificationTrigger).to receive(:join_request_on_create)
          create :join_request, user: user, status: :accepted
        }
      end
    end

    describe "notify is received" do
      describe "outing" do
        let(:neighborhood) { create(:neighborhood) }

        it {
          expect_any_instance_of(PushNotificationTrigger).not_to receive(:notify)
          create :outing, user: user
        }

        it {
          expect_any_instance_of(PushNotificationTrigger).to receive(:notify)
          create :outing, user: user, neighborhoods: [neighborhood]
        }
      end

      describe "join_request" do
        it {
          expect_any_instance_of(PushNotificationTrigger).to receive(:notify)
          create :join_request, user: user, status: :accepted
        }

        it {
          expect_any_instance_of(PushNotificationTrigger).not_to receive(:notify)
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
          expect_any_instance_of(PushNotificationTrigger).to receive(:outing_on_update)
          outing.update_attribute(:title, "foo")
        }
      end
    end

    describe "notify is received" do
      describe "outing with participant" do
        let!(:outing) { create :outing, user: user, status: :open }
        let!(:join_request) { create :join_request, user: participant, joinable: outing, status: :accepted }

        it {
          expect_any_instance_of(PushNotificationTrigger).to receive(:notify)
          outing.update_attribute(:title, "foo")
        }
      end

      describe "outing without participant" do
        let!(:outing) { create :outing, user: user, status: :open }

        it {
          expect_any_instance_of(PushNotificationTrigger).not_to receive(:notify)
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
          expect_any_instance_of(PushNotificationTrigger).to receive(:outing_on_cancel)
          outing.update_attribute(:status, :cancelled)
        }
      end
    end

    describe "notify is received" do
      describe "outing with participant" do
        let!(:outing) { create :outing, user: user, status: :open }
        let!(:join_request) { create :join_request, user: participant, joinable: outing, status: :accepted }

        it {
          expect_any_instance_of(PushNotificationTrigger).to receive(:notify)
          outing.update_attribute(:status, :cancelled)
        }
      end

      describe "outing without participant" do
        let!(:outing) { create :outing, user: user, status: :open }

        it {
          expect_any_instance_of(PushNotificationTrigger).not_to receive(:notify)
          outing.update_attribute(:status, :cancelled)
        }
      end
    end
  end

  describe "on change outing status" do
    let(:starts_at) { 1.hour.from_now }
    let(:ends_at) { 2.hours.from_now }

    let!(:outing) { create :outing, user: user, status: :open, metadata: { starts_at: starts_at, ends_at: ends_at } }
    let!(:join_request) { create :join_request, user: participant, joinable: outing, status: :accepted }

    describe "on_cancel" do
      context "on_cancel is received" do
        before { expect_any_instance_of(PushNotificationTrigger).to receive(:outing_on_cancel) }

        it { outing.update_attribute(:status, :cancelled) }
      end

      context "notification is received" do
        before { expect_any_instance_of(PushNotificationTrigger).to receive(:notify) }

        it { outing.update_attribute(:status, :cancelled) }
      end

      describe "outing without participant" do
        let!(:outing_without_participant) { create :outing, user: user, status: :open }

        before { expect_any_instance_of(PushNotificationTrigger).not_to receive(:notify) }

        it { outing_without_participant.update_attribute(:status, :cancelled) }
      end
    end

    describe "notification sent on status closed only when in the future" do
      before { expect_any_instance_of(PushNotificationTrigger).to receive(:notify) }

      context "on close" do
        let(:starts_at) { 1.hour.from_now }
        let(:ends_at) { 2.hours.from_now }

        it { outing.update_attribute(:status, :closed) }
      end
    end

    describe "no notification sent on status other than cancelled" do
      before { expect_any_instance_of(PushNotificationTrigger).not_to receive(:notify) }

      context "on close when in the past" do
        let(:starts_at) { 2.hours.ago }
        let(:ends_at) { 1.hour.ago }

        it { outing.update_attribute(:status, :closed) }
      end

      context "on blacklisted" do
        it { outing.update_attribute(:status, :blacklisted) }
      end

      context "on suspended" do
        it { outing.update_attribute(:status, :suspended) }
      end

      context "on full" do
        it { outing.update_attribute(:status, :full) }
      end
    end
  end

  describe "notify" do
    describe "set neighborhood_ids on outing does push notification" do
      let!(:outing) { create :outing, user: user, participants: [participant] }
      let!(:neighborhood) { create :neighborhood }

      it {
        expect_any_instance_of(PushNotificationTrigger).to receive(:notify)

        outing.update_attribute(:neighborhood_ids, [neighborhood.id])
      }
    end

    describe "create entourage push notification" do
      let(:partner) { create(:partner, name: "foo", postal_code: "75008") }
      let(:user) { create(:public_user, partner: partner) }

      let(:follower) { create(:public_user) }
      let(:entourage) { create :entourage, user: user }

      context "entourage creator has followers" do
        let!(:following) { create :following, user: follower, partner: partner }

        before { expect_any_instance_of(PushNotificationTrigger).to receive(:notify) }

        it { entourage }
      end

      context "entourage creator does not have followers" do
        let(:entourage) { create :entourage }

        before { expect_any_instance_of(PushNotificationTrigger).not_to receive(:notify) }

        it { entourage }
      end
    end

    describe "text chat_message" do
      let(:conversation) { ConversationService.build_conversation(participant_ids: [user.id, participant.id]) }
      let(:chat_message) { build(:chat_message, messageable: conversation, user: user, message_type: :text, content: "foobar") }

      context "conversation creation does not push any notification" do
        it {
          expect_any_instance_of(PushNotificationTrigger).not_to receive(:notify)

          conversation.public = false
          conversation.create_from_join_requests!
          conversation.save
        }
      end

      context "chat_message creation does push notification" do
        before {
          conversation.public = false
          conversation.create_from_join_requests!
          conversation.save
        }

        it {
          expect_any_instance_of(PushNotificationTrigger).to receive(:notify).with(
            sender_id: chat_message.user_id,
            referent: conversation,
            instance: conversation,
            users: [participant],
            params: {
              object: "John D.",
              content: "foobar",
              extra: {
                group_type: "conversation",
                joinable_id: conversation.id,
                joinable_type: "Entourage",
                type: "NEW_CHAT_MESSAGE"
              },
            }
          )

          chat_message.save
        }
      end
    end

    describe "outing_on_update" do
      let(:starts_at) { 1.hour.from_now }
      let(:ends_at) { 2.hours.from_now }

      let!(:outing) { create :outing, user: user, status: :open, title: "Café", metadata: { starts_at: starts_at, ends_at: ends_at } }
      let!(:join_request) { create :join_request, user: participant, joinable: outing, status: :accepted }

      context "update title sends one notification" do
        it {
          expect_any_instance_of(PushNotificationTrigger).to receive(:notify).once

          outing.update_attribute(:title, "Théâtre")
        }
      end

      context "update title" do
        it {
          expect_any_instance_of(PushNotificationTrigger).to receive(:notify).with(
            sender_id: outing.user_id,
            referent: outing,
            instance: outing.reload,
            users: [participant],
            params: {
              object: "Théâtre",
              content: "L'événement prévu le #{I18n.l(outing.starts_at.to_date)} a été modifié",
            }
          )

          outing.update_attribute(:title, "Théâtre")
        }
      end

      context "update starts_at" do
        it {
          expect_any_instance_of(PushNotificationTrigger).to receive(:notify).with(
            sender_id: outing.user_id,
            referent: outing,
            instance: outing.reload,
            users: [participant],
            params: {
              object: "Café",
              content: "L'événement prévu le #{I18n.l(Time.now.to_date)} a été modifié. Il se déroulera le #{I18n.l(90.minutes.from_now.to_date)}, au #{outing.metadata[:display_address]}",
            }
          )

          outing.metadata[:starts_at] = 90.minutes.from_now
          outing.save
        }
      end

      context "update status to cancel" do
        it {
          expect_any_instance_of(PushNotificationTrigger).to receive(:notify).with(
            sender_id: outing.user_id,
            referent: outing,
            instance: outing.reload,
            users: [participant],
            params: {
              object: "Café",
              content: "Cet événement prévu le #{I18n.l(outing.starts_at.to_date)} vient d'être annulé",
            }
          )

          outing.update_attribute(:status, :cancelled)
        }
      end

      context "update status to closed with starts_at in the future" do
        let(:starts_at) { 1.hour.from_now }
        let(:ends_at) { 2.hours.from_now }

        it {
          expect_any_instance_of(PushNotificationTrigger).to receive(:notify).with(
            sender_id: outing.user_id,
            referent: outing,
            instance: outing.reload,
            users: [participant],
            params: {
              object: "Café",
              content: "Cet événement prévu le #{I18n.l(outing.starts_at.to_date)} vient d'être annulé",
            }
          )

          outing.update_attribute(:status, :closed)
        }
      end

      context "update status to closed with starts_at in the past" do
        let(:starts_at) { 2.hours.ago }
        let(:ends_at) { 1.hour.ago }

        it {
          expect_any_instance_of(PushNotificationTrigger).not_to receive(:notify)

          outing.update_attribute(:status, :closed)
        }
      end
    end

    describe "join_request on create" do
      let!(:outing) { create :outing, user: user, status: :open, title: "Café", metadata: { starts_at: Time.now, ends_at: 2.days.from_now} }

      it {
        expect_any_instance_of(PushNotificationTrigger).to receive(:notify).with(
          sender_id: participant.id,
          referent: outing,
          instance: participant,
          users: [outing.user],
          params: {
            object: "Nouveau membre",
            content: "Jane D. vient de rejoindre votre événement \"Café\" du #{I18n.l(outing.starts_at.to_date)}",
            extra: {
              joinable_id: outing.id,
              joinable_type: "Entourage",
              group_type: "outing",
              type: "JOIN_REQUEST_ACCEPTED",
              user_id: participant.id
            }
          }
        )

        create :join_request, user: participant, joinable: outing, status: :accepted
      }
    end
  end
end
