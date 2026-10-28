require 'rails_helper'
include AuthHelper

describe Admin::ConversationsController do
  describe 'GET index' do
    let!(:admin) { admin_basic_login }

    let!(:unread_conversation) { FactoryBot.create(:conversation) }
    let!(:read_conversation) { FactoryBot.create(:conversation) }

    let!(:unread_chat_message) { FactoryBot.create(:chat_message, messageable: unread_conversation) }
    let!(:read_chat_message) { FactoryBot.create(:chat_message, messageable: read_conversation) }

    # distinct creator participants ensure distinct uuid_v2 hashes for the two conversations
    let!(:unread_creator_join_request) {
      FactoryBot.create(:join_request, joinable: unread_conversation, user: unread_conversation.user, status: :accepted)
    }
    let!(:read_creator_join_request) {
      FactoryBot.create(:join_request, joinable: read_conversation, user: read_conversation.user, status: :accepted)
    }

    let!(:unread_join_request) {
      FactoryBot.create(:join_request, joinable: unread_conversation, user: admin, status: :accepted, unread_messages_count: 1)
    }
    let!(:read_join_request) {
      FactoryBot.create(:join_request, joinable: read_conversation, user: admin, status: :accepted, unread_messages_count: 0)
    }

    before { get :index }

    it { expect(response).to be_successful }
    it { expect(assigns(:conversations).map(&:id)).to contain_exactly(unread_conversation.id, read_conversation.id) }
    it { expect(assigns(:unread_count)).to eq(1) }

    context 'filtered on unread' do
      before { get :index, params: { filter: 'unread' } }

      it { expect(assigns(:conversations).map(&:id)).to contain_exactly(unread_conversation.id) }
      it { expect(assigns(:unread_count)).to eq(1) }
    end
  end

  describe 'rendering (regression: missing partial / template errors)' do
    render_views

    let!(:admin) { admin_basic_login }

    it 'renders index' do
      get :index
      expect(response).to be_successful
      expect(response.body).to include('Non-lus (0)')
    end
  end
end
