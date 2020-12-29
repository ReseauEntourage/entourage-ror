require 'rails_helper'

RSpec.describe ConversationMessageBroadcastJob do

  describe 'close!' do
    let!(:conversation_message_broadcast) { FactoryGirl.create(:conversation_message_broadcast, content: "Contenu de la diffusion") }
    let(:organization) { FactoryGirl.create(:organization) }
    let!(:users) { FactoryGirl.create_list(:user, 2, organization: organization) }
    let!(:admin) { FactoryGirl.create(:user, admin: true, organization: organization) }

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
    it { expect { job }.to change { admin.conversation_messages.count }.by(2) }
    it {
      job
      expect(ConversationMessage.ordered.last.content).to eq("Contenu de la diffusion")
    }
  end
end
