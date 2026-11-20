require 'rails_helper'

# End-to-end: real PushNotificationTrigger -> PushNotificationService (NotificationPermission)
# -> NotificationJob / InappNotification. Only the push token lookup is stubbed.
#
# Specs of PushNotificationTriggerObserver mock `notify`: they cannot detect a notification
# that is silently dropped by NotificationPermission (ie. an instance missing from PUSH_INSTANCES).
RSpec.describe PushNotificationTrigger, type: :service do
  describe 'chat_message_on_create redirection' do
    let(:author) { create(:public_user) }
    let(:recipient) { create(:public_user) }

    # NotificationJob.perform_later(sender, object, content, push_token, community_slug, extra, badge)
    let(:pushes) { [] }
    let(:extras) { pushes.map { |args| args[5] } }

    before do
      allow_any_instance_of(UserServices::UserApplications).to receive(:app_tokens).and_return([double(push_token: 'token')])
      allow(NotificationJob).to receive(:perform_later) { |*args| pushes << args }
    end

    def join(user, joinable)
      create(:join_request, user: user, joinable: joinable, status: :accepted)
    end

    # records are created first (observers fire on creation), then the trigger is played once
    def notify!(chat_message)
      pushes.clear
      InappNotification.delete_all

      described_class.new(chat_message, :create, {}).run
    end

    context 'post in a neighborhood' do
      let(:neighborhood) { create(:neighborhood) }
      let!(:post) do
        join(author, neighborhood)
        join(recipient, neighborhood)
        create(:chat_message, messageable: neighborhood, user: author)
      end

      before { notify!(post) }

      it 'sends a push to the group and targets the post with chat_message_id' do
        expect(extras).to be_present
        expect(extras).to all(include(instance: 'neighborhood', instance_id: neighborhood.id, chat_message_id: post.id))
      end

      it 'creates an inapp notification targeting the post with chat_message_id' do
        expect(InappNotification.where(user: recipient)).to contain_exactly(
          have_attributes(instance: 'neighborhood', instance_id: neighborhood.id, chat_message_id: post.id)
        )
      end
    end

    context 'comment on a neighborhood post' do
      let(:neighborhood) { create(:neighborhood) }
      let!(:post) do
        join(author, neighborhood)
        join(recipient, neighborhood)
        create(:chat_message, messageable: neighborhood, user: recipient)
      end
      let!(:comment) { create(:chat_message, messageable: neighborhood, user: author, parent: post) }

      before { notify!(comment) }

      it 'sends a push targeting the post (post_id) and the comment (chat_message_id)' do
        expect(extras).to be_present
        expect(extras).to all(include(instance: 'neighborhood_post', post_id: post.id, chat_message_id: comment.id))
      end

      it 'creates an inapp notification targeting the post (post_id) and the comment (chat_message_id)' do
        expect(InappNotification.where(user: recipient)).to contain_exactly(
          have_attributes(instance: 'neighborhood_post', post_id: post.id, chat_message_id: comment.id)
        )
      end
    end

    # The PushNotificationLinker maps outing chat messages to "conversation" so that they pass
    # NotificationPermission.notify_push? (outing_post is not in PUSH_INSTANCES, EN-8462).
    context 'post in an outing' do
      let(:outing) { create(:outing) }
      let!(:post) do
        join(author, outing)
        join(recipient, outing)
        create(:chat_message, messageable: outing, user: author)
      end

      before { notify!(post) }

      it 'still sends a push, with chat_message_id' do
        expect(extras).to be_present
        expect(extras).to all(include(instance: 'conversation', instance_id: outing.id, chat_message_id: post.id))
      end
    end

    context 'comment on an outing post' do
      let(:outing) { create(:outing) }
      let!(:post) do
        join(author, outing)
        join(recipient, outing)
        create(:chat_message, messageable: outing, user: recipient)
      end
      let!(:comment) { create(:chat_message, messageable: outing, user: author, parent: post) }

      before { notify!(comment) }

      it 'still sends a push, with chat_message_id' do
        expect(extras).to be_present
        expect(extras).to all(include(chat_message_id: comment.id))
      end
    end
  end
end
