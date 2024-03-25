require 'rails_helper'

RSpec.describe PushNotificationTriggerObserver, type: :model do
  include ActiveJob::TestHelper

  let(:paris) { { latitude: 48.87, longitude: 2.33 } }
  let(:nantes) { { latitude: 47.22, longitude: -1.55 } }
  let(:address_paris) { FactoryBot.create(:address, latitude: paris[:latitude], longitude: paris[:longitude]) }

  let(:user) { create :public_user, first_name: "John" }
  let(:user_paris) { create :public_user, first_name: "Doe", addresses: [address_paris], goal: :ask_for_help }
  let(:participant) { create :public_user, first_name: "Jane" }

  # define shared_examples on PushNotificationTrigger
  [
    :notify,
    :outing_on_update,
    :outing_on_cancel,
    :outing_on_day_before,
    :chat_message_on_create,
    :post_on_create,
    :comment_on_create,
    :user_reaction_on_create,
    :public_chat_message_on_create,
    :private_chat_message_on_create,
    :survey_response_on_create,
  ].each do |method_name|
    shared_examples("call_#{method_name}".to_sym) do
      it { expect_any_instance_of(PushNotificationTrigger).to receive(method_name) }
    end

    shared_examples("no_call_#{method_name}".to_sym) do
      it { expect_any_instance_of(PushNotificationTrigger).not_to receive(method_name) }
    end
  end

  # entourage_on_create
  shared_examples :call_entourage_on_create do
    it { expect_any_instance_of(PushNotificationTrigger).to receive(:async_entourage_on_create) }
    it { expect_any_instance_of(PushNotificationTrigger).to receive(:entourage_on_create_for_followers) }
    it { expect_any_instance_of(PushNotificationTrigger).to receive(:entourage_on_create_for_neighbors) }
  end

  shared_examples :no_call_entourage_on_create do
    it { expect_any_instance_of(PushNotificationTrigger).not_to receive(:async_entourage_on_create) }
    it { expect_any_instance_of(PushNotificationTrigger).not_to receive(:entourage_on_create_for_followers) }
    it { expect_any_instance_of(PushNotificationTrigger).not_to receive(:entourage_on_create_for_neighbors) }
  end

  describe "outing_on_day_before" do
    let(:outing) { create :outing }
    let(:subject) { PushNotificationTrigger.new(Outing.find(outing.id), :day_before, Hash.new).run }

    before { outing }
    after { subject }

    context "without member" do
      include_examples :call_outing_on_day_before
      include_examples :no_call_notify
    end

    context "with member" do
      let!(:join_request) { create :join_request, user: participant, joinable: outing, status: :accepted }

      include_examples :call_outing_on_day_before
      include_examples :call_notify
    end
  end

  describe "entourage" do
    let(:entourage) { create :entourage }

    let(:contribution) { create :contribution, user: user }
    let(:solicitation) { create :solicitation, user: user }
    let(:outing) { create :outing, user: user }

    describe "on_create" do
      after { entourage }

      context "contribution" do
        let(:entourage) { contribution }
        include_examples :no_call_entourage_on_create
      end

      context "solicitation" do
        let(:entourage) { solicitation }
        include_examples :no_call_entourage_on_create
      end

      context "outing" do
        let(:entourage) { outing }
        include_examples :no_call_entourage_on_create
      end
    end

    describe "on_update" do
      let(:subject) { entourage.update_attribute(:title, "foo") }

      after { subject }

      describe "on validated" do
        let!(:moderation) { entourage.set_moderation_dates_and_save }

        context "contribution" do
          let(:entourage) { contribution }
          include_examples :no_call_outing_on_update
        end

        context "solicitation" do
          let(:entourage) { solicitation }
          include_examples :no_call_outing_on_update
        end

        context "outing without participant" do
          let(:entourage) { outing }
          include_examples :call_outing_on_update
          include_examples :no_call_notify
        end

        context "outing with participant" do
          let(:starts_at) { 1.hour.from_now }
          let(:ends_at) { 2.hours.from_now }

          let(:entourage) { create :outing, user: user, status: :open, title: "Café", metadata: { starts_at: starts_at, ends_at: ends_at } }
          let!(:join_request) { create :join_request, user: participant, joinable: entourage, status: :accepted }

          context "update title" do
            let(:subject) {
              entourage.title = "Thé"
              entourage.save
            }

            include_examples :call_outing_on_update
            include_examples :no_call_notify
          end

          context "update title and latitude" do
            let(:subject) {
              entourage.title = "foo"
              entourage.latitude = 0.1
              entourage.save
            }

            include_examples :call_outing_on_update
            include_examples :call_notify
          end

          context "update latitude" do
            let(:subject) {
              entourage.latitude = 0.1
              entourage.save
            }

            include_examples :call_outing_on_update
            include_examples :call_notify
          end

          context "update starts_at" do
            let(:subject) {
              entourage.metadata[:starts_at] = 90.minutes.from_now
              entourage.save
            }

            include_examples :call_outing_on_update
            include_examples :call_notify

            it {
              expect_any_instance_of(PushNotificationTrigger).to receive(:notify).with(
                sender_id: entourage.user_id,
                referent: entourage,
                instance: entourage.reload,
                users: [participant],
                params: {
                  object: PushNotificationTrigger::I18nStruct.new(instance: kind_of(Entourage), field: :title),
                  content: PushNotificationTrigger::I18nStruct.new(i18n: 'push_notifications.outing.update', i18n_args: [I18n.l(Time.now.to_date), I18n.l(90.minutes.from_now.to_date), entourage.metadata[:display_address]]),
                  extra: {
                    tracking: :outing_on_update
                  }
                }
              )
            }
          end

          context "update status to cancel" do
            let(:subject) { entourage.update_attribute(:status, :cancelled) }

            it {
              expect_any_instance_of(PushNotificationTrigger).to receive(:notify).with(
                sender_id: entourage.user_id,
                referent: entourage,
                instance: entourage.reload,
                users: [participant],
                params: {
                  object: PushNotificationTrigger::I18nStruct.new(instance: kind_of(Entourage), field: :title),
                  content: PushNotificationTrigger::I18nStruct.new(i18n: 'push_notifications.outing.cancel', i18n_args: I18n.l(entourage.starts_at.to_date)),
                  extra: {
                    tracking: :outing_on_cancel
                  }
                }
              )
            }
          end

          context "update status to closed with starts_at in the future" do
            let(:starts_at) { 1.hour.from_now }
            let(:ends_at) { 2.hours.from_now }

            let(:subject) { entourage.update_attribute(:status, :closed) }

            it {
              expect_any_instance_of(PushNotificationTrigger).to receive(:notify).with(
                sender_id: entourage.user_id,
                referent: entourage,
                instance: entourage.reload,
                users: [participant],
                params: {
                  object: PushNotificationTrigger::I18nStruct.new(instance: kind_of(Entourage), field: :title),
                  content: PushNotificationTrigger::I18nStruct.new(i18n: 'push_notifications.outing.cancel', i18n_args: I18n.l(entourage.starts_at.to_date)),
                  extra: {
                    tracking: :outing_on_cancel
                  }
                }
              )
            }
          end

          context "update status to closed with starts_at in the past" do
            let(:starts_at) { 2.hours.ago }
            let(:ends_at) { 1.hour.ago }

            let(:subject) { entourage.update_attribute(:status, :closed) }

            include_examples :no_call_notify
          end
        end
      end

      describe "on not validated" do
        let!(:moderation) {
          entourage.update_attribute(:status, :blacklisted)
          entourage.set_moderation_dates_and_save
        }

        context "outing with participant" do
          let(:entourage) { outing }
          let!(:join_request) { create :join_request, user: participant, joinable: entourage, status: :accepted }

          include_examples :no_call_outing_on_update
          include_examples :no_call_notify
        end

        context "outing without participant" do
          let(:entourage) { outing }
          include_examples :no_call_outing_on_update
          include_examples :no_call_notify
        end
      end
    end

    describe "on_update to cancel" do
      let!(:entourage) { outing }
      let!(:moderation) {
        entourage.update_attribute(:status, :open)
        entourage.set_moderation_dates_and_save
      }

      after { entourage.update_attribute(:status, :cancelled) }

      context "outing with participant" do
        let!(:join_request) { create :join_request, user: participant, joinable: entourage, status: :accepted }

        include_examples :call_outing_on_cancel
        include_examples :call_notify
      end

      context "outing without participant" do
        include_examples :call_outing_on_cancel
        include_examples :no_call_notify
      end
    end

    describe "on_update status" do
      let(:starts_at) { 1.hour.from_now }
      let(:ends_at) { 2.hours.from_now }

      let!(:entourage) { create :outing, user: user, status: :open, metadata: { starts_at: starts_at, ends_at: ends_at } }
      let!(:moderation) {
        entourage.update_attribute(:status, :open)
        entourage.set_moderation_dates_and_save
      }

      let!(:join_request) { create :join_request, user: participant, joinable: entourage, status: :accepted }

      describe "notification sent on status closed only when in the future" do
        context "on close" do
          let(:starts_at) { 1.hour.from_now }
          let(:ends_at) { 2.hours.from_now }

          after { entourage.update_attribute(:status, :closed) }
          include_examples :call_notify
        end
      end

      describe "no notification sent on status other than cancelled" do
        context "on close when in the past" do
          let(:starts_at) { 2.hours.ago }
          let(:ends_at) { 1.hour.ago }

          after { entourage.update_attribute(:status, :closed) }
          include_examples :no_call_notify
        end

        context "on blacklisted" do
          after { entourage.update_attribute(:status, :blacklisted) }
          include_examples :no_call_notify
        end

        context "on suspended" do
          after { entourage.update_attribute(:status, :suspended) }
          include_examples :no_call_notify
        end

        context "on full" do
          after { entourage.update_attribute(:status, :full) }
          include_examples :no_call_notify
        end
      end
    end
  end

  describe "entourage_moderation" do
    let(:status) { :open }

    let(:moderation) {
      entourage.update_attribute(:status, status)
      entourage.set_moderation_dates_and_save
    }

    describe "contribution" do
      let!(:entourage) { create :contribution, user: user }

      describe "on_create" do
        describe "validated" do
          let(:status) { :open }

          after { moderation }

          include_examples :call_entourage_on_create
        end

        describe "blacklisted" do
          let(:status) { :blacklisted }

          after { moderation }

          include_examples :no_call_entourage_on_create
        end
      end
    end
  end

  describe "chat_message" do
    let(:neighborhood) { create :neighborhood }

    context "text chat_message" do
      after { create :chat_message, user: user, message_type: :text }

      include_examples :call_chat_message_on_create
    end

    context "broadcast chat_message" do
      let!(:broadcast) { FactoryBot.create(:user_message_broadcast) }

      after { create :chat_message, user: user, message_type: :broadcast, metadata: { conversation_message_broadcast_id: broadcast.id } }

      include_examples :call_chat_message_on_create
    end

    context "status chat_message" do
      after { create :chat_message, user: user, message_type: :status_update, metadata: { status: :foo, outcome_success: true } }

      include_examples :no_call_post_on_create
      include_examples :no_call_comment_on_create
    end

    context "public_chat_message" do
      let(:contribution) { create :contribution, user: user, participants: [user_paris] }
      let(:subject) { create :chat_message, user: user, message_type: :text, messageable: contribution, content: "foo" }

      after { subject }

      include_examples :call_public_chat_message_on_create
      include_examples :no_call_post_on_create
      include_examples :no_call_comment_on_create

      context "notify" do
        after { subject }

        it {
          expect_any_instance_of(PushNotificationTrigger).to receive(:notify).with(
            sender_id: user.id,
            referent: Entourage.find(contribution.id),
            instance: an_instance_of(ChatMessage),
            users: [user_paris],
            params: {
              object: PushNotificationTrigger::I18nStruct.new(text: "John D. - #{contribution.title}"),
              content: PushNotificationTrigger::I18nStruct.new(instance: kind_of(ChatMessage), field: :content),
              extra: {
                tracking: :public_chat_message_on_create,
                group_type: "action",
                joinable_type: "Entourage",
                joinable_id: contribution.id,
                type: "NEW_CHAT_MESSAGE"
              }
            }
          )
        }
      end
    end

    context "private_chat_message" do
      after { create :private_chat_message, user: user, message_type: :text }

      include_examples :call_private_chat_message_on_create
      include_examples :no_call_post_on_create
    end

    context "post chat_message in neighborhood" do
      after { create :chat_message, user: user, message_type: :text, messageable: neighborhood }

      include_examples :no_call_private_chat_message_on_create
      include_examples :call_post_on_create
      include_examples :no_call_comment_on_create
    end

    context "comment with no notification" do
      let(:publication) { create :chat_message, messageable: neighborhood, user: user, message_type: :text }
      let!(:comment) { create :chat_message, messageable: neighborhood, parent: publication, user: user, message_type: :text }

      context "sender is publisher" do
        after { create :chat_message, messageable: neighborhood, user: user, message_type: :text, parent: publication }

        include_examples :no_call_notify
      end
    end

    context "comment with notification" do
      let(:john) { create :public_user, first_name: "John", last_name: "Doe" }
      let(:jane) { create :public_user, first_name: "Jane", last_name: "Doe" }

      let(:publication) { create :chat_message, messageable: neighborhood, user: user, message_type: :text }
      let!(:comment_1) { create :chat_message, messageable: neighborhood, parent: publication, user: user, message_type: :text }
      let!(:comment_2) { create :chat_message, messageable: neighborhood, parent: publication, user: john, message_type: :text }
      let!(:comment_3) { create :chat_message, messageable: neighborhood, parent: publication, user: john, message_type: :text }
      let!(:comment_4) { create :chat_message, messageable: neighborhood, parent: publication, user: jane, message_type: :text }

      context "sender" do
        after { create :chat_message, messageable: neighborhood, user: user, message_type: :text, parent: publication }

        include_examples :no_call_post_on_create
        include_examples :call_comment_on_create
      end

      context "sender is publisher" do
        after { create :chat_message, messageable: neighborhood, user: user, message_type: :text, parent: publication }

        include_examples :call_notify

        it {
          expect_any_instance_of(PushNotificationTrigger).to receive(:notify).with(
            sender_id: user.id,
            referent: neighborhood,
            instance: publication,
            users: [john, jane],
            params: {
              object: PushNotificationTrigger::I18nStruct.new(instance: neighborhood, field: :title),
              content: PushNotificationTrigger::I18nStruct.new(i18n: 'push_notifications.comment.create', i18n_args: publication.content),
              extra: {
                tracking: :comment_on_create_to_neighborhood
              }
            }
          )
        }
      end

      context "sender is commentator" do
        after { create :chat_message, messageable: neighborhood, user: john, message_type: :text, parent: publication }

        include_examples :call_notify

        it {
          expect_any_instance_of(PushNotificationTrigger).to receive(:notify).with(
            sender_id: john.id,
            referent: neighborhood,
            instance: publication,
            users: [user, jane],
            params: {
              object: PushNotificationTrigger::I18nStruct.new(instance: neighborhood, field: :title),
              content: PushNotificationTrigger::I18nStruct.new(i18n: 'push_notifications.comment.create', i18n_args: publication.content),
              extra: {
                tracking: :comment_on_create_to_neighborhood
              }
            }
          )
        }
      end
    end

    context "reaction to post" do
      let(:publication) { create :chat_message, messageable: neighborhood, user: user, message_type: :text }

      before { publication }

      after { create :user_reaction, instance: publication }

      include_examples :call_user_reaction_on_create
      include_examples :call_notify
    end

    context "reaction to post but reactioner is publisher" do
      let(:publication) { create :chat_message, messageable: neighborhood, user: user, message_type: :text }

      before { publication }

      after { create :user_reaction, instance: publication, user: publication.user }

      include_examples :call_user_reaction_on_create
      include_examples :no_call_notify
    end

    describe "text chat_message" do
      let(:conversation) { ConversationService.build_conversation(participant_ids: [user.id, participant.id]) }
      let(:chat_message) { build(:chat_message, messageable: conversation, user: user, message_type: :text, content: "foobar") }
      let(:translation) { build :translation, instance: chat_message }

      context "conversation creation does not push any notification" do
        after {
          conversation.public = false
          conversation.create_from_join_requests!
          conversation.save
        }

        include_examples :no_call_notify
      end

      context "chat_message creation does push notification" do
        before {
          conversation.public = false
          conversation.create_from_join_requests!
          conversation.save
        }

        after { translation.save }

        it {
          expect_any_instance_of(PushNotificationTrigger).to receive(:notify).with(
            sender_id: chat_message.user_id,
            referent: conversation,
            instance: conversation,
            users: [participant],
            params: {
              object: PushNotificationTrigger::I18nStruct.new(text: "John D."),
              content: PushNotificationTrigger::I18nStruct.new(instance: chat_message, field: :content),
              extra: {
                tracking: :private_chat_message_on_create,
                group_type: "conversation",
                joinable_id: conversation.id,
                joinable_type: "Entourage",
                type: "NEW_CHAT_MESSAGE"
              },
            }
          )
        }
      end
    end

    describe "survey_response" do
      let(:survey) { create(:survey) }
      let!(:chat_message) { create :chat_message, messageable: neighborhood, user: user, survey: survey }

      context "surveyer is publisher" do
        after { create(:survey_response, chat_message: chat_message, user: user, responses: [false, true]) }

        include_examples :call_survey_response_on_create
        include_examples :no_call_notify
      end

      context "surveyer is not publisher" do
        after { create(:survey_response, chat_message: chat_message, responses: [false, true]) }

        include_examples :call_survey_response_on_create
        include_examples :call_notify
      end
    end
  end

  # after_create
  describe "after_create" do
    let(:entourage) { create :entourage }
    let(:moderation) { entourage.set_moderation_dates_and_save }

    describe "on_create is received" do
      describe "outing attached to neighborhoods" do
        let!(:entourage) { create :outing, user: user, neighborhoods: [create(:neighborhood)] }

        after { moderation }

        it { expect_any_instance_of(PushNotificationService).to receive(:send_notification) }
        it { expect_any_instance_of(InappNotificationServices::Builder).to receive(:instanciate) }

        it { expect_any_instance_of(PushNotificationTrigger).to receive(:neighborhoods_entourage_on_create) }
        it { expect_any_instance_of(PushNotificationTrigger).to receive(:async_entourage_on_create) }
        it { expect_any_instance_of(PushNotificationTrigger).to receive(:entourage_on_create_for_followers) }
        it { expect_any_instance_of(PushNotificationTrigger).not_to receive(:entourage_on_create_for_neighbors) }
      end

      describe "outing not attached to neighborhoods" do
        let!(:entourage) { create :outing, user: user }

        after { moderation }

        it { expect_any_instance_of(PushNotificationService).not_to receive(:send_notification) }
        it { expect_any_instance_of(InappNotificationServices::Builder).not_to receive(:instanciate) }

        it { expect_any_instance_of(PushNotificationTrigger).not_to receive(:neighborhoods_entourage_on_create) }
        it { expect_any_instance_of(PushNotificationTrigger).to receive(:async_entourage_on_create) }
        it { expect_any_instance_of(PushNotificationTrigger).to receive(:entourage_on_create_for_followers) }
        it { expect_any_instance_of(PushNotificationTrigger).not_to receive(:entourage_on_create_for_neighbors) }
      end

      describe "contribution" do
        let!(:entourage) { create :contribution, user: user }

        after { moderation }

        it { expect_any_instance_of(PushNotificationTrigger).to receive(:async_entourage_on_create) }
        it { expect_any_instance_of(PushNotificationTrigger).to receive(:entourage_on_create_for_followers) }
        it { expect_any_instance_of(PushNotificationTrigger).to receive(:entourage_on_create_for_neighbors) }
      end

      describe "contribution with neighbor" do
        let!(:entourage) { create :contribution, user: user, latitude: paris[:latitude], longitude: paris[:longitude] }
        let!(:notification_permission) { create :notification_permission, user: user_paris }

        before { user_paris }

        after { moderation }

        it { expect_any_instance_of(PushNotificationTrigger).to receive(:entourage_on_create_for_neighbors) }
        it { expect_any_instance_of(PushNotificationTrigger).to receive(:notify) }
        it { expect_any_instance_of(InappNotificationServices::Builder).to receive(:instanciate) }
        it { expect_any_instance_of(InappNotification).to receive(:save) }
      end

      describe "contribution with neighbor far away" do
        let!(:entourage) { create :contribution, user: user, latitude: nantes[:latitude], longitude: nantes[:longitude] }

        after { moderation }

        it { expect_any_instance_of(PushNotificationTrigger).to receive(:entourage_on_create_for_neighbors) }
        it { expect_any_instance_of(PushNotificationTrigger).not_to receive(:notify) }
      end

      describe "contribution without neighbor" do
        let!(:entourage) { create :contribution, user: user, latitude: paris[:latitude], longitude: paris[:longitude] }

        after { moderation }

        it { expect_any_instance_of(PushNotificationTrigger).to receive(:entourage_on_create_for_neighbors) }
        it { expect_any_instance_of(PushNotificationTrigger).not_to receive(:notify) }
      end

      describe "contribution with ask_for_help neighbor" do
        let(:user_paris) { create :public_user, first_name: "Doe", addresses: [address_paris], goal: :ask_for_help }

        let!(:entourage) { create :contribution, user: user, latitude: paris[:latitude], longitude: paris[:longitude] }
        let!(:notification_permission) { create :notification_permission, user: user_paris }

        before { user_paris }

        after { moderation }

        it { expect_any_instance_of(PushNotificationTrigger).to receive(:notify) }
      end

      describe "contribution with offer_help neighbor" do
        let(:user_paris) { create :public_user, first_name: "Doe", addresses: [address_paris], goal: :offer_help }

        let!(:entourage) { create :contribution, user: user, latitude: paris[:latitude], longitude: paris[:longitude] }
        let!(:notification_permission) { create :notification_permission, user: user_paris }

        before { user_paris }

        after { moderation }

        it { expect_any_instance_of(PushNotificationTrigger).not_to receive(:notify) }
      end

      describe "solicitation with ask_for_help neighbor" do
        let(:user_paris) { create :public_user, first_name: "Doe", addresses: [address_paris], goal: :ask_for_help }

        let!(:entourage) { create :solicitation, user: user, latitude: paris[:latitude], longitude: paris[:longitude] }
        let!(:notification_permission) { create :notification_permission, user: user_paris }

        before { user_paris }

        after { moderation }

        it { expect_any_instance_of(PushNotificationTrigger).not_to receive(:notify) }
      end

      describe "solicitation with offer_help neighbor" do
        let(:user_paris) { create :public_user, first_name: "Doe", addresses: [address_paris], goal: :offer_help }

        let!(:entourage) { create :solicitation, user: user, latitude: paris[:latitude], longitude: paris[:longitude] }
        let!(:notification_permission) { create :notification_permission, user: user_paris }

        before { user_paris }

        after { moderation }

        it { expect_any_instance_of(PushNotificationTrigger).to receive(:notify) }
      end

      describe "chat_message" do
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
        let(:outing) { create :outing, user: user, status: :open }
        let(:moderation) { outing.set_moderation_dates_and_save }

        after { moderation }

        context "without neighborhood" do
          include_examples :no_call_notify
        end

        context "with neighborhood" do
          let(:outing) { create :outing, user: user, neighborhoods: [neighborhood] }

          include_examples :call_notify
        end

        context "with neighborhood and as first occurrence" do
          let(:outing) { create :outing, user: user, neighborhoods: [neighborhood], recurrency_identifier: "abc" }
          let!(:outing_recurrence) { create(:outing_recurrence, identifier: "abc") }

          include_examples :call_notify
        end

        context "with neighborhood and as second occurrence" do
          let!(:outing_recurrence) { create(:outing_recurrence, identifier: "abc") }
          let!(:outing_0) { create :outing, title: "outing_0", user: user, neighborhoods: [neighborhood], recurrency_identifier: "abc", metadata: { starts_at: 2.minutes.ago } }
          let(:outing) { create :outing, title: "outing", user: user, neighborhoods: [neighborhood], recurrency_identifier: "abc", metadata: { starts_at: 1.minute.ago } }

          include_examples :no_call_notify
        end
      end

      describe "join_request" do
        context "accepted" do
          after { create :join_request, user: user, status: :accepted }

          include_examples :call_notify
        end

        context "pending" do
          after { create :join_request, user: user, status: :pending }

          include_examples :no_call_notify
        end
      end
    end
  end

  describe "neighborhood" do
    describe "set neighborhood_ids on outing does push notification" do
      let(:outing) { create :outing, user: user, participants: [participant] }
      let!(:moderation) { outing.set_moderation_dates_and_save }
      let!(:neighborhood) { create :neighborhood }

      after { outing.update_attribute(:neighborhood_ids, [neighborhood.id]) }

      include_examples :call_notify
    end
  end

  describe "notify" do
    describe "create entourage push notification" do
      let(:partner) { create(:partner, name: "foo", postal_code: "75008") }
      let(:user) { create(:public_user, partner: partner) }

      let(:follower) { create(:public_user) }
      let!(:entourage) { create :entourage, user: user }
      let(:moderation) { entourage.set_moderation_dates_and_save }

      context "entourage creator has followers" do
        let!(:following) { create :following, user: follower, partner: partner }

        include_examples :call_notify

        after { moderation }
      end

      context "entourage creator does not have followers" do
        let!(:entourage) { create :entourage }

        after { moderation }

        include_examples :no_call_notify
      end
    end

    describe "join_request on create" do
      let!(:outing) { create :outing, user: user, status: :open, title: "Café", metadata: { starts_at: Time.now, ends_at: 2.days.from_now} }

      after { create :join_request, user: participant, joinable: outing, status: :accepted }

      it {
        expect_any_instance_of(PushNotificationTrigger).to receive(:notify).with(
          sender_id: participant.id,
          referent: outing,
          instance: participant,
          users: [outing.user],
          params: {
            object: PushNotificationTrigger::I18nStruct.new(i18n: 'push_notifications.join_request.new'),
            content: PushNotificationTrigger::I18nStruct.new(i18n: 'push_notifications.outing.create', i18n_args: I18n.l(outing.starts_at.to_date)),
            extra: {
              tracking: :join_request_on_create_to_outing,
              joinable_id: outing.id,
              joinable_type: "Entourage",
              group_type: "outing",
              type: "JOIN_REQUEST_ACCEPTED",
              user_id: participant.id
            }
          }
        )
      }
    end
  end

  describe "content_for_create_action" do
    let(:subject) { PushNotificationTrigger.new(record, :foo, Hash.new).content_for_create_action(record) }

    context "on join_request" do
      let(:record) { create :join_request }

      it { expect(subject).to be_nil }
    end

    context "on neighborhood" do
      let(:record) { create :neighborhood }

      it { expect(subject).to be_nil }
    end

    context "on conversation" do
      let(:record) { create :conversation }

      it { expect(subject).to be_nil }
    end

    context "on outing" do
      let(:record) { create :outing }

      it { expect(subject).to be_nil }
    end

    context "on solicitation" do
      let(:record) { create :solicitation }

      it { expect(subject).to eq(PushNotificationTrigger::I18nStruct.new(i18n: 'push_notifications.solicitation.create', i18n_args: nil)) }
    end

    context "on clothes solicitation" do
      let(:record) { create :solicitation, section: :clothes }

      it { expect(subject).to eq(PushNotificationTrigger::I18nStruct.new(i18n: 'push_notifications.solicitation.create_section', i18n_args: "vêtement")) }
    end

    context "on contribution" do
      let(:record) { create :contribution }

      it { expect(subject).to eq(PushNotificationTrigger::I18nStruct.new(i18n: 'push_notifications.contribution.create')) }
    end
  end
end
