require 'rails_helper'

RSpec.describe ConversationMessageBroadcastJob do

  describe 'perform' do
    let!(:conversation_message_broadcast) { FactoryBot.create(:conversation_message_broadcast, content: "Contenu de la diffusion") }
    let(:organization) { FactoryBot.create(:organization) }
    let!(:users) { FactoryBot.create_list(:user, 2, organization: organization) }
    let!(:admin) { FactoryBot.create(:user, admin: true, organization: organization) }

    let(:job) {
      ConversationMessageBroadcastJob.new.perform(
        conversation_message_broadcast.id,
        admin.id,
        users.map(&:id),
        conversation_message_broadcast.content
      )
      users.map(&:reload)
      admin.reload
    }

    it { expect { job }.to change { ConversationMessage.count }.by(2) }
    it { expect { job }.to change { ChatMessage.count }.by(2) }
    it { expect { job }.to change { admin.conversation_messages.count }.by(2) }
    it {
      job
      expect(ConversationMessage.ordered.last.content).to eq("Contenu de la diffusion")
      expect(conversation_message_broadcast.reload.sent_users_count).to eq(2)
    }
  end
end
