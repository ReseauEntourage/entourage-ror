require 'rails_helper'

RSpec.describe UserImpactStatsObserver do
  let(:user) { create(:public_user) }
  let(:alice) { create(:public_user) }

  describe 'actions' do
    it 'enqueues the action_creations recompute of its creator on creation' do
      expect(UserImpactStatsJob).to receive(:perform_async).with(user.id, UserStat::ACTION_CREATIONS)

      create(:entourage, user: user)
    end

    it 'enqueues it for contributions and solicitations too' do
      expect(UserImpactStatsJob).to receive(:perform_async).with(user.id, UserStat::ACTION_CREATIONS).twice

      create(:contribution, user: user)
      create(:solicitation, user: user)
    end

    context 'with an existing action' do
      let!(:action) { create(:entourage, user: user, status: :open) }

      it 'enqueues the recompute on a status change' do
        expect(UserImpactStatsJob).to receive(:perform_async).with(user.id, UserStat::ACTION_CREATIONS)

        action.update!(status: :suspended)
      end

      it 'does not enqueue on another change' do
        expect(UserImpactStatsJob).not_to receive(:perform_async)

        action.update!(title: 'another title')
      end
    end

    it 'does not enqueue for events, conversations or neighborhoods' do
      expect(UserImpactStatsJob).not_to receive(:perform_async)

      create(:outing, user: user)
      create(:conversation, user: user)
      create(:neighborhood, user: user)
    end
  end

  describe 'messages' do
    let(:neighborhood) { create(:neighborhood) }
    let(:conversation) { create(:conversation, participants: [user, alice]) }

    it 'enqueues neighborhood_messages for a neighborhood post' do
      expect(UserImpactStatsJob).to receive(:perform_async).with(user.id, UserStat::NEIGHBORHOOD_MESSAGES)

      create(:chat_message, messageable: neighborhood, user: user)
    end

    it 'enqueues conversation_members for a private message' do
      conversation

      expect(UserImpactStatsJob).to receive(:perform_async).with(user.id, UserStat::CONVERSATION_MEMBERS)

      create(:chat_message, messageable: conversation, user: user)
    end

    it 'enqueues the recompute when a message is deleted' do
      message = create(:chat_message, messageable: neighborhood, user: user)

      expect(UserImpactStatsJob).to receive(:perform_async).with(user.id, UserStat::NEIGHBORHOOD_MESSAGES)

      message.update!(status: :deleted)
    end

    it 'does not enqueue for an outing or action message' do
      outing = create(:outing)
      # the action's own creation enqueues action_creations
      action = create(:entourage)

      expect(UserImpactStatsJob).not_to receive(:perform_async)

      create(:chat_message, messageable: outing, user: user)
      create(:chat_message, messageable: action, user: user)
    end

    it 'does not enqueue for a broadcast' do
      broadcast = create(:neighborhood_message_broadcast)

      expect(UserImpactStatsJob).not_to receive(:perform_async)

      create(:chat_message, messageable: neighborhood, user: user, message_type: :broadcast,
        metadata: { conversation_message_broadcast_id: broadcast.id })
    end
  end

  describe 'conversation memberships' do
    let(:bob) { create(:public_user) }
    let(:carol) { create(:public_user) }
    let(:conversation) { create(:conversation, participants: [user, alice, bob]) }

    before do
      create(:chat_message, messageable: conversation, user: user)
      create(:chat_message, messageable: conversation, user: alice)
    end

    it 'enqueues conversation_members for every other author when a member joins' do
      expect(UserImpactStatsJob).to receive(:perform_async).with(user.id, UserStat::CONVERSATION_MEMBERS)
      expect(UserImpactStatsJob).to receive(:perform_async).with(alice.id, UserStat::CONVERSATION_MEMBERS)

      create(:join_request, joinable: conversation, user: carol, status: :accepted)
    end

    it 'does not enqueue for the new member, who did not write' do
      allow(UserImpactStatsJob).to receive(:perform_async)

      create(:join_request, joinable: conversation, user: carol, status: :accepted)

      expect(UserImpactStatsJob).not_to have_received(:perform_async).with(carol.id, anything)
    end

    it 'does not enqueue on a membership status change' do
      expect(UserImpactStatsJob).not_to receive(:perform_async)

      conversation.join_requests.find_by(user: bob).update!(status: JoinRequest::HIDDEN_STATUS)
    end

    it 'does not enqueue for an outing or neighborhood membership' do
      outing = create(:outing)
      neighborhood = create(:neighborhood)

      expect(UserImpactStatsJob).not_to receive(:perform_async)

      create(:join_request, joinable: outing, user: carol, status: :accepted)
      create(:join_request, joinable: neighborhood, user: carol, status: :accepted)
    end

    # jobs run inline in specs
    it 'updates the count of those who already wrote when a member joins' do
      expect { create(:join_request, joinable: conversation, user: carol, status: :accepted) }
        .to change { user.reload.user_stat.conversation_members_count }.from(2).to(3)
    end
  end
end
