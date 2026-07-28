require 'rails_helper'

RSpec.describe ConversationMessageBroadcastJob do
  describe 'perform' do
    let!(:conversation_message_broadcast) { FactoryBot.create(:user_message_broadcast, content: 'Contenu de la diffusion') }
    let!(:users) { FactoryBot.create_list(:user, 2) }
    let!(:admin) { FactoryBot.create(:user, admin: true) }

    let(:job) {
      users.each do |user|
        ConversationMessageBroadcastJob.new.perform(
          conversation_message_broadcast.id,
          admin.id,
          user.id,
          conversation_message_broadcast.content
        )
      end
      users.map(&:reload)
      admin.reload
    }

    before {
      allow_any_instance_of(UserMessageBroadcast).to receive(:user_ids).and_return(users.map(&:id))
    }

    it { expect { job }.to change { ChatMessage.count }.by(2) }
    it { expect { job }.to change { admin.chat_messages.count }.by(2) }
    it {
      job
      expect(ChatMessage.ordered.last.content).to eq('Contenu de la diffusion')
      expect(conversation_message_broadcast.reload.sent_recipients_count).to eq(2)
    }

    it 'starts from a NULL sent_recipients_count (no default in schema)' do
      expect(conversation_message_broadcast.sent_recipients_count).to be_nil
      job
      expect(conversation_message_broadcast.reload.sent_recipients_count).to eq(2)
    end

    it 'increments the existing count instead of overwriting it' do
      conversation_message_broadcast.update_column(:sent_recipients_count, 5)
      job
      expect(conversation_message_broadcast.reload.sent_recipients_count).to eq(7)
    end

    it 'increments sent_recipients_count with a single atomic UPDATE per recipient, never a read-then-write' do
      expect(ConversationMessageBroadcast).to receive(:update_counters)
        .with(conversation_message_broadcast.id, sent_recipients_count: 1)
        .twice.and_call_original

      job
    end
  end
end
