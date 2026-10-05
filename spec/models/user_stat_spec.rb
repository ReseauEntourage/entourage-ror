require 'rails_helper'

RSpec.describe UserStat, type: :model do
  let(:user) { create(:public_user) }
  let(:alice) { create(:public_user) }
  let(:bob) { create(:public_user) }

  it { should belong_to(:user) }

  it 'is reachable from the user' do
    stat = UserStat.create!(user: user)

    expect(user.reload.user_stat).to eq(stat)
  end

  def refresh counter
    UserStat.refresh!(user.id, counter)
    user.reload.user_stat
  end

  describe '.refresh!' do
    context 'action_creations' do
      subject { refresh(UserStat::ACTION_CREATIONS).action_creations_count }

      context 'with open and closed actions' do
        before do
          create(:entourage, user: user, status: :open)
          create(:entourage, user: user, status: :closed)
        end

        it { expect(subject).to eq(2) }
      end

      context 'with moderated actions' do
        before do
          create(:entourage, user: user, status: :open)
          create(:entourage, user: user, status: :blacklisted)
          create(:entourage, user: user, status: :suspended)
        end

        it { expect(subject).to eq(1) }
      end

      context 'when moderation is lifted' do
        let!(:action) { create(:entourage, user: user, status: :suspended) }

        before { action.update_column(:status, :open) }

        it { expect(subject).to eq(1) }
      end

      context 'with events, groups and conversations but no action' do
        before do
          create(:outing, user: user)
          create(:neighborhood, user: user)
          create(:conversation, user: user)
        end

        it { expect(subject).to eq(0) }
      end

      context 'with actions created by someone else' do
        before { create(:entourage, user: alice) }

        it { expect(subject).to eq(0) }
      end
    end

    context 'neighborhood_messages' do
      let(:neighborhood) { create(:neighborhood) }

      subject { refresh(UserStat::NEIGHBORHOOD_MESSAGES).neighborhood_messages_count }

      context 'with posts and comments' do
        before do
          posts = create_list(:chat_message, 2, messageable: neighborhood, user: user)
          create(:chat_message, messageable: neighborhood, user: user, parent: posts.first)
          create(:chat_message, messageable: neighborhood, user: user, parent: posts.first)
          create(:chat_message, messageable: neighborhood, user: user, parent: posts.last)
        end

        it { expect(subject).to eq(5) }
      end

      context 'with an updated message' do
        before { create(:chat_message, messageable: neighborhood, user: user).update_column(:status, :updated) }

        it { expect(subject).to eq(1) }
      end

      [:deleted, :scheduled, :offensive, :offensible].each do |status|
        context "with a #{status} message" do
          before do
            create(:chat_message, messageable: neighborhood, user: user)
            create(:chat_message, messageable: neighborhood, user: user).update_column(:status, status)
          end

          it { expect(subject).to eq(1) }
        end
      end

      UserStat::UNCOUNTED_MESSAGE_TYPES.each do |message_type|
        context "with a #{message_type} message" do
          before do
            create(:chat_message, messageable: neighborhood, user: user).update_column(:message_type, message_type)
          end

          it { expect(subject).to eq(0) }
        end
      end

      context 'with reactions only' do
        let(:post) { create(:chat_message, messageable: neighborhood, user: alice) }

        before { create(:user_reaction, user: user, instance: post) }

        it { expect(subject).to eq(0) }
      end

      context 'with messages outside neighborhoods' do
        before do
          create(:chat_message, messageable: create(:outing), user: user)
          create(:chat_message, messageable: create(:entourage), user: user)
          create(:chat_message, messageable: create(:conversation, participants: [user, alice]), user: user)
        end

        it { expect(subject).to eq(0) }
      end

      context 'with posts by someone else' do
        before { create(:chat_message, messageable: neighborhood, user: alice) }

        it { expect(subject).to eq(0) }
      end
    end

    context 'conversation_members' do
      subject { refresh(UserStat::CONVERSATION_MEMBERS).conversation_members_count }

      context 'with conversations with distinct members' do
        before do
          create(:chat_message, messageable: create(:conversation, participants: [user, alice]), user: user)
          create(:chat_message, messageable: create(:conversation, participants: [user, bob]), user: user)
        end

        it { expect(subject).to eq(2) }
      end

      context 'with the same member in several conversations' do
        # a one-to-one conversation is unique per pair of participants
        # (uuid_v2), so alice is shared through a group conversation; its
        # participants are added bob first so that its intermediate uuid_v2
        # never matches the one-to-one conversation's
        before do
          create(:chat_message, messageable: create(:conversation, participants: [user, alice]), user: user)
          create(:chat_message, messageable: create(:conversation, participants: [bob, alice, user]), user: user)
        end

        it { expect(subject).to eq(2) }
      end

      context 'with a conversation where the user never wrote' do
        before do
          create(:chat_message, messageable: create(:conversation, participants: [user, alice]), user: alice)
        end

        it { expect(subject).to eq(0) }
      end

      context 'when the counterpart archived or left the conversation' do
        let(:conversation) { create(:conversation, participants: [user, alice, bob]) }

        before do
          create(:chat_message, messageable: conversation, user: user)
          conversation.join_requests.find_by(user: alice).update_column(:status, JoinRequest::HIDDEN_STATUS)
          conversation.join_requests.find_by(user: bob).update_column(:status, JoinRequest::CANCELLED_STATUS)
        end

        it { expect(subject).to eq(2) }
      end

      context "when the user's only message is deleted" do
        before do
          create(:chat_message, messageable: create(:conversation, participants: [user, alice]), user: user)
            .update_column(:status, :deleted)
        end

        it { expect(subject).to eq(0) }
      end

      context 'with a system message only' do
        before do
          create(:chat_message, messageable: create(:conversation, participants: [user, alice]), user: user)
            .update_column(:message_type, :broadcast)
        end

        it { expect(subject).to eq(0) }
      end

      context 'with messages outside conversations' do
        before { create(:chat_message, messageable: create(:outing, participants: [user, alice]), user: user) }

        it { expect(subject).to eq(0) }
      end
    end

    context 'row handling' do
      before do
        create(:entourage, user: user)
        # jobs run inline in specs: drop the row the observer just created
        UserStat.delete_all
      end

      it 'creates the row of a user who has none' do
        expect { UserStat.refresh!(user.id, UserStat::ACTION_CREATIONS) }.to change { UserStat.where(user: user).count }.from(0).to(1)
      end

      it 'leaves the other counters of the row untouched' do
        UserStat.create!(user: user, neighborhood_messages_count: 7, conversation_members_count: 3)

        UserStat.refresh!(user.id, UserStat::ACTION_CREATIONS)

        expect(user.reload.user_stat).to have_attributes(
          action_creations_count: 1,
          neighborhood_messages_count: 7,
          conversation_members_count: 3
        )
      end

      it 'rejects an unknown counter' do
        expect { UserStat.refresh!(user.id, 'foo') }.to raise_error(ArgumentError)
      end
    end
  end

  describe '.backfill!' do
    let(:neighborhood) { create(:neighborhood) }
    let(:inactive) { create(:public_user) }
    let(:outsider) { create(:public_user) }

    before do
      # users in the range are created first, outsider last so that its id is
      # above the range
      [user, alice, bob, inactive]

      create(:entourage, user: user)
      create(:entourage, user: user, status: :blacklisted)
      post = create(:chat_message, messageable: neighborhood, user: user)
      create(:chat_message, messageable: neighborhood, user: user, parent: post)
      create(:chat_message, messageable: create(:conversation, participants: [user, alice]), user: user)
      create(:chat_message, messageable: create(:conversation, participants: [bob, alice, user]), user: user)
      create(:chat_message, messageable: neighborhood, user: alice)
      create(:chat_message, messageable: neighborhood, user: outsider)

      # jobs run inline in specs: start the backfill from an empty table
      UserStat.delete_all
    end

    let(:in_range) { [user, alice, bob, inactive].map(&:id) }

    subject { UserStat.backfill!(from_id: in_range.min, to_id: in_range.max) }

    def counters_of record
      record.reload.user_stat&.slice(:action_creations_count, :neighborhood_messages_count, :conversation_members_count)
    end

    it 'computes the same counts as .refresh!' do
      subject
      backfilled = counters_of(user)

      UserStat.where(user: user).delete_all
      UserStat::COUNTERS.each { |counter| UserStat.refresh!(user.id, counter) }

      expect(backfilled).to eq(counters_of(user))
      expect(backfilled).to eq(
        'action_creations_count' => 1,
        'neighborhood_messages_count' => 2,
        'conversation_members_count' => 2
      )
    end

    it 'creates rows only for users with activity in the range' do
      subject

      expect(UserStat.where(user_id: in_range).pluck(:user_id)).to match_array([user.id, alice.id])
    end

    it 'leaves users outside the range untouched' do
      subject

      expect(UserStat.where(user: outsider)).to be_empty
    end

    it 'resets an existing row of a user without activity' do
      UserStat.create!(user: inactive, action_creations_count: 4)

      subject

      expect(counters_of(inactive)).to eq(
        'action_creations_count' => 0,
        'neighborhood_messages_count' => 0,
        'conversation_members_count' => 0
      )
    end

    it 'is idempotent' do
      subject
      first_run = UserStat.where(user_id: in_range).order(:user_id).map { |stat| counters_of(stat.user) }

      UserStat.backfill!(from_id: in_range.min, to_id: in_range.max)

      expect(UserStat.where(user_id: in_range).order(:user_id).map { |stat| counters_of(stat.user) }).to eq(first_run)
    end
  end
end
