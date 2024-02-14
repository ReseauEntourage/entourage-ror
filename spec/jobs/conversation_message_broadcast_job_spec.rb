require 'rails_helper'

RSpec.describe ConversationMessageBroadcastJob do
  describe 'perform' do
    let!(:conversation_message_broadcast) { FactoryBot.create(:user_message_broadcast, content: "Contenu de la diffusion") }
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

    it { expect { job }.to change { ConversationMessage.count }.by(2) }
    it { expect { job }.to change { ChatMessage.count }.by(2) }
    it { expect { job }.to change { admin.conversation_messages.count }.by(2) }
    it {
      job
      expect(ConversationMessage.ordered.last.content).to eq("Contenu de la diffusion")
      expect(conversation_message_broadcast.reload.sent_recipients_count).to eq(2)
    }
  end
end
