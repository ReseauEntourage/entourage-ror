require 'rails_helper'

describe V1::ConversationSerializer do
  include ActiveModel::Serializers
  include ActiveModel::Serializers::JSON

  describe 'fields' do
    let(:user) { FactoryBot.create(:public_user) }
    let(:participant) { create :public_user, first_name: :Jane }
    let(:conversation) { FactoryBot.create(:conversation, participants: [user, participant]) }
    let!(:chat_message) { FactoryBot.create(:chat_message, messageable: conversation, content: "foo")}

    let(:serialized) { V1::ConversationSerializer.new(conversation, scope: { user: user }).serializable_hash }

    it { expect(serialized).to have_key(:id) }
    it { expect(serialized).to have_key(:status) }
    it { expect(serialized).to have_key(:type) }
    it { expect(serialized).to have_key(:name) }
    it { expect(serialized).to have_key(:image_url) }
    it { expect(serialized).to have_key(:last_message) }
    it { expect(serialized).to have_key(:number_of_unread_messages) }
    it { expect(serialized).to have_key(:has_personal_post) }
    it { expect(serialized).to have_key(:user) }

    context 'values' do
      it { expect(serialized[:id]).to eq(conversation.id) }
      it { expect(serialized[:type]).to eq(:private) }
      it { expect(serialized[:name]).to eq('Jane D.') }
      it { expect(serialized[:last_message][:text]).to eq("foo") }
      it { expect(serialized[:number_of_unread_messages]).to eq(1) }
      it { expect(serialized[:has_personal_post]).to eq(false) }
    end

    context 'as outing' do
      let(:conversation) { FactoryBot.create(:outing, group_type: :outing, participants: [user]) }

      it { expect(serialized).to have_key(:section) }
      it { expect(serialized[:type]).to eq(:outing) }
    end

    context 'with personal post' do
      let!(:chat_message) { FactoryBot.create(:chat_message, messageable: conversation, user: user)}

      it { expect(serialized[:has_personal_post]).to eq(true) }
    end

    context 'without unread messages' do
      before { JoinRequest.where(user_id: user.id, joinable_id: conversation.id).first.update_attribute(:last_message_read, 1.second.from_now) }

      it { expect(serialized[:number_of_unread_messages]).to eq(0) }
    end
  end
end
