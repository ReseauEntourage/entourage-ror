require 'rails_helper'

RSpec.describe ReconcileUnreadMessagesCountsJob do
  let(:user) { create(:public_user) }
  let(:other) { create(:public_user) }
  let(:conversation) { create(:conversation, participants: [user, other]) }
  let(:join_request) { conversation.join_requests.find_by(user: other) }

  subject { described_class.new.perform }

  context 'when a conversation had recent chat activity' do
    before do
      create(:chat_message, messageable: conversation, user: user, created_at: 10.minutes.ago)
      # simulate a lost UnreadChatMessageJob run: the counter never got updated
      join_request.update_column(:unread_messages_count, 0)
    end

    it 're-triggers UnreadChatMessageJob and corrects the stale counter' do
      subject

      expect(join_request.reload.unread_messages_count).to eq(1)
    end
  end

  context 'when a conversation only had old chat activity' do
    before do
      create(:chat_message, messageable: conversation, user: user, created_at: (described_class::LOOKBACK + 1.hour).ago)
      join_request.update_column(:unread_messages_count, 0)
    end

    it 'does not touch it' do
      subject

      expect(join_request.reload.unread_messages_count).to eq(0)
    end
  end

  context 'when there is no chat activity at all' do
    it 'does nothing' do
      expect { subject }.not_to raise_error
    end
  end
end
