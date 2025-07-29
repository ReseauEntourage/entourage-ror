require 'rails_helper'

RSpec.describe ConversationMessageBroadcast, type: :model do
  let(:user) { create(:public_user) }

  describe '#content_for_user' do
    let(:conversation_message_broadcast) { create(:conversation_message_broadcast, content: 'Bonjour {{first_name}}, votre email est {{email}}, votre téléphone est {{phone}} et votre ville {{city}}.') }

    let(:subject) { conversation_message_broadcast.content_for_user(user) }

    it { expect(subject).to eq("Bonjour #{user.first_name}, votre email est #{user.email}, votre téléphone est #{user.phone} et votre ville #{user.city}.") }
  end
end
