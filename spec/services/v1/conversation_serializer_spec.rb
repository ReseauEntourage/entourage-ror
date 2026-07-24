require 'rails_helper'

describe V1::ConversationSerializer do
  include ActiveModel::Serializers
  include ActiveModel::Serializers::JSON

  describe 'fields' do
    let(:user) { FactoryBot.create(:public_user) }
    let(:participant) { create :public_user, first_name: :Jane }
    let(:conversation) { FactoryBot.create(:conversation, participants: [user, participant]) }
    let!(:chat_message) { FactoryBot.create(:chat_message, messageable: conversation, content: 'foo')}

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
      it { expect(serialized[:last_message][:text]).to eq('foo') }
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
      before { JoinRequest.where(user_id: user.id, joinable_id: conversation.id).first.set_chat_messages_as_read }

      it { expect(serialized[:number_of_unread_messages]).to eq(0) }
    end
  end

  describe '#current_join_request' do
    let(:user) { FactoryBot.create(:public_user) }
    let(:participant) { FactoryBot.create(:public_user) }
    let(:conversation) { FactoryBot.create(:conversation, participants: [user, participant]) }
    let(:serializer) { V1::ConversationSerializer.new(conversation, scope: { user: user }) }

    context 'not preloaded by the controller' do
      it 'falls back to scanning the lazy join_requests' do
        join_request = JoinRequest.where(user_id: user.id, joinable_id: conversation.id).first

        expect(serializer.current_join_request).to eq(join_request)
      end
    end

    context 'preloaded by the controller (see Preloaders::Entourage.preload_current_join_request)' do
      it 'uses the preloaded value instead of scanning the lazy join_requests' do
        join_request = JoinRequest.where(user_id: user.id, joinable_id: conversation.id).first
        conversation.current_join_request = join_request

        expect(serializer).not_to receive(:lazy_join_requests)
        expect(serializer.current_join_request).to eq(join_request)
      end
    end
  end

  describe '#members' do
    let(:user) { FactoryBot.create(:public_user) }
    let(:participant) { FactoryBot.create(:public_user) }
    let(:conversation) { FactoryBot.create(:conversation, participants: [user, participant]) }

    context 'accepted_members is not preloaded' do
      it 'queries accepted_members with a SQL limit' do
        expect(conversation.association(:accepted_members).loaded?).to be false

        members = V1::ConversationSerializer.new(conversation, scope: { user: user }).members

        expect(members.map(&:id)).to match_array([user.id, participant.id])
      end
    end

    context 'accepted_members is preloaded' do
      it 'slices the preloaded array in Ruby instead of issuing a new query' do
        preloaded = ::Entourage.includes(:accepted_members).find(conversation.id)
        expect(preloaded.association(:accepted_members).loaded?).to be true

        expect(preloaded.accepted_members).not_to receive(:limit)

        members = V1::ConversationSerializer.new(preloaded, scope: { user: user }).members

        expect(members.map(&:id)).to match_array([user.id, participant.id])
      end
    end
  end

  describe '#blockers (Blockers#other_participant_id)' do
    let(:user) { FactoryBot.create(:public_user) }
    let(:participant) { FactoryBot.create(:public_user) }
    let(:conversation) { FactoryBot.create(:conversation, participants: [user, participant]) }
    let!(:user_blocked_user) { FactoryBot.create(:user_blocked_user, user: user, blocked_user: participant) }

    context 'accepted_members is not preloaded' do
      it 'falls back to member_ids to find the other participant' do
        expect(conversation.association(:accepted_members).loaded?).to be false

        serialized = V1::ConversationSerializer.new(conversation, scope: { user: user }).serializable_hash

        expect(serialized[:blockers]).to eq([:me])
      end
    end

    context 'accepted_members is preloaded' do
      it 'uses the preloaded accepted_members to find the other participant' do
        preloaded = ::Entourage.includes(:accepted_members).find(conversation.id)
        expect(preloaded.association(:accepted_members).loaded?).to be true

        serialized = V1::ConversationSerializer.new(preloaded, scope: { user: user }).serializable_hash

        expect(serialized[:blockers]).to eq([:me])
      end
    end
  end
end
