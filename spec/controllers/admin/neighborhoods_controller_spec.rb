require 'rails_helper'
include AuthHelper

describe Admin::NeighborhoodsController do
  let!(:user) { admin_basic_login }

  describe 'GET #index' do
    let(:result) { assigns(:neighborhoods).map(&:id) }

    context 'has neighborhoods' do
      let!(:neighborhood_list) { create_list(:neighborhood, 2) }

      before { get :index }

      it { expect(result).to match_array(neighborhood_list.map(&:id)) }
    end

    context 'has no neighborhoods' do
      before { get :index }

      it { expect(result).to eq([]) }
    end
  end

  describe 'GET #edit' do
    let!(:neighborhood) { create(:neighborhood) }

    before { get :edit, params: { id: neighborhood.to_param } }

    it { expect(assigns(:neighborhood).id).to eq(neighborhood.id) }
  end

  describe 'PUT #update' do
    let!(:neighborhood) { create(:neighborhood, name: 'foo') }

    context 'common field' do
      before { put :update, params: { id: neighborhood.id, neighborhood: { name: 'bar' } } }

      it { expect(neighborhood.reload.name).to eq('bar')}
    end
  end

  describe 'POST message' do
    let(:params) { { content: 'foo' } }
    let(:request) { post :message, params: { id: neighborhood.id, chat_message: params } }

    context 'member' do
      let!(:neighborhood) { create(:neighborhood, participants: [user]) }

      it { expect { request }.not_to change { JoinRequest.count } }
      it { expect { request }.to change { ChatMessage.count }.by(1) }
    end

    context 'not a member' do
      let!(:neighborhood) { create(:neighborhood) }

      it { expect { request }.to change { JoinRequest.count }.by(1) }
      it { expect { request }.to change { ChatMessage.count }.by(1) }
    end

    context 'cancelled member' do
      let!(:neighborhood) { create(:neighborhood, cancelled_participants: [user]) }

      it { expect { request }.not_to change { JoinRequest.count } }
      it { expect { request }.to change { ChatMessage.count }.by(1) }

      context 'update join_request status' do
        let(:join_request) { JoinRequest.find_by(joinable: neighborhood, user: user) }

        before { request }

        it { expect(join_request.reload.status).to eq(JoinRequest::ACCEPTED_STATUS) }
      end
    end

    context 'message comment' do
      let(:params) { { content: 'foo', parent_id: chat_message.id } }

      let!(:neighborhood) { create(:neighborhood, participants: [user]) }
      let!(:chat_message) { create(:chat_message, messageable: neighborhood)}

      it { expect { request }.not_to change { JoinRequest.count } }
      it { expect { request }.to change { ChatMessage.count }.by(1) }

      context 'child of her parent' do
        before { request }

        it { expect(chat_message.reload.child_ids).to eq([ChatMessage.last.id]) }
      end
    end
  end

  describe 'DELETE destroy_message' do
    let(:neighborhood) { FactoryBot.create(:neighborhood) }
    let(:chat_message) { FactoryBot.create(:chat_message, messageable: neighborhood, content: 'foo') }
    let(:result) { chat_message.reload }

    before { delete :destroy_message, params: { id: neighborhood.id, chat_message_id: chat_message.id }}

    it { expect(result.deleted?).to eq(true) }
    it { expect(result.deleter_id).to eq(user.id) }
    it { expect(result.content).to eq('') }
    it { expect(result.content(true)).to eq('foo') }
  end

  describe 'PUT #join' do
    let(:neighborhood) { FactoryBot.create(:neighborhood) }

    context 'user is admin' do
      before { put :join, params: { id: neighborhood.id } }

      it { expect(neighborhood.reload.member_ids).to match_array([neighborhood.user_id, user.id])}
    end

    context 'user is not admin' do
      let!(:user) { user_basic_login }

      before { put :join, params: { id: neighborhood.id } }

      it { expect(neighborhood.reload.member_ids).to match_array([neighborhood.user_id])}
    end
  end

  describe 'PUT #unjoin' do
    let(:neighborhood) { FactoryBot.create(:neighborhood, participants: [user]) }

    context 'user is admin' do
      before { put :unjoin, params: { id: neighborhood.id } }

      it { expect(neighborhood.reload.member_ids).to match_array([neighborhood.user_id])}
    end

    context 'user is not admin' do
      let!(:user) { user_basic_login }

      before { put :unjoin, params: { id: neighborhood.id } }

      it { expect(neighborhood.reload.member_ids).to match_array([neighborhood.user_id, user.id])}
    end
  end
end
